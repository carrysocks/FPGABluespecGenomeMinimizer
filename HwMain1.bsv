import FIFO::*;
import BRAM::*;
import Clocks::*;
import Vector::*;
import BRAMFIFO::*;

import PcieCtrl::*;

interface HwMainIfc;
endinterface

typedef 4096 Sequence_Size;
typedef Bit#(32) Sequence; // Assuming each sequence segment is 32 bits

module mkHwMain#(PcieUserIfc pcie)
(HwMainIfc);

    FIFO#(Sequence) seq_input <- mkFIFO;
    FIFO#(Sequence) resultQ <- mkSizedBRAMFIFO(valueOf(Sequence_Size));

	let kmer = 31;
	let m = 7;
    // ... [You might need additional components or data structures here]

    rule getDataFromHost;
        let w <- pcie.dataReceive;
        Bit#(20) a = w.addr;
        Sequence d = w.data;

		$display("gdfh\n");

        /* We won't use Last 2-Bits for PCIe Address */
        Bit#(20) off = a >> 2;

        // Assume 0 is the sequence data channel
        if (off == 0) begin
            seq_input.enq(d);
        end
    endrule

	// function Bit#(2) getNucleotide(Sequence s, Integer i);
	// 	return (s >> (i*2)) & 2'b11;
	// endfunction	

    // rule processSequence;
	// 	Sequence s = seq_input.first;
	// 	Sequence rev = 0;

	// 	$display("si = %b", s);

	// 	resultQ.enq(s);
		
	// 	// Step 1: Compute reverse complement
	// 	// for (Integer i = 0; i < 32; i = i + 1) begin
	// 	// 	Bit#(2) nucleotide = (s >> (30 - i*2))[1:0];
	// 	// 	Bit#(2) revNucleotide;
	// 	// 	case (nucleotide)
	// 	// 		2'b00: revNucleotide = 2'b10; // A->T
	// 	// 		2'b01: revNucleotide = 2'b11; // C->G
	// 	// 		2'b10: revNucleotide = 2'b00; // T->A
	// 	// 		2'b11: revNucleotide = 2'b01; // G->C
	// 	// 	endcase
	// 	// 	rev = (rev << 2) | zeroExtend(revNucleotide);
	// 	// end

	// 	// $display("rev = %b", rev);
	
	// 	// Step 2: For each Kmer-sized window, find the minimum M-sized sequence.
	// 	// for (Integer i = 0; i <= (32-kmer); i = i + 1) begin
	// 	// 	Sequence sub_f = (s >> (i*2)) & ((1 << (kmer*2)) - 1);
	// 	// 	Sequence sub_r = (rev >> ((32 - kmer - i)*2)) & ((1 << (kmer*2)) - 1);
			
	// 	// 	// Extract M-sized sequence from sub_f and sub_r
	// 	// 	Sequence minM_f = sub_f & ((1 << (m*2)) - 1); // Get last M nucleotides
	// 	// 	Sequence minM_r = sub_r & ((1 << (m*2)) - 1); 
	
	// 	// 	for (Integer j = 1; j <= (kmer-m); j = j + 1) begin
	// 	// 		Sequence tempM_f = (sub_f >> (j*2)) & ((1 << (m*2)) - 1);
	// 	// 		Sequence tempM_r = (sub_r >> (j*2)) & ((1 << (m*2)) - 1);
	
	// 	// 		if (tempM_f < minM_f) minM_f = tempM_f;
	// 	// 		if (tempM_r < minM_r) minM_r = tempM_r;
	// 	// 	end
	
	// 	// 	Sequence minSeq = minM_f < minM_r ? minM_f : minM_r;
	// 	// 	resultQ.enq(minSeq);
	// 	// end
	
	// 	seq_input.deq;
	// endrule
		

    rule sendDataToHost;
        let r <- pcie.dataReq;
        let a = r.addr;
        let offset = (a>>2);

        if (offset == 0) begin
            pcie.dataSend(r, resultQ.first);
            resultQ.deq;
        end else begin
            $display("Wrong Request from channel %d", r.addr);
        end
    endrule
endmodule
