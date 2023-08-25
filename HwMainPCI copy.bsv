import FIFO::*;
import BRAM::*;
import Clocks::*;
import Vector::*;
import BRAMFIFO::*;

import PcieCtrl::*;

interface HwMainIfc;
endinterface

typedef 4096 Matrix_Size;

module mkHwMain#(PcieUserIfc pcie) 
	(HwMainIfc);

    FIFO#(Bit#(2)) genomeData <- mkFIFO;
    Reg#(Bit#(32)) kmer <- mkReg(32'hFFFFFFFF);
    Reg#(Bit#(32)) min <- mkReg(32'd4294967295);
    Reg#(Bit#(32)) m <- mkReg(32'd7);
    Reg#(Bit#(32)) count <- mkReg(0);

	rule getDataFromHost;
		let w <- pcie.dataReceive;
		Bit#(20) a = w.addr;
		Bit#(32) d = w.data;

        Bit#(2) d_converted = d[1:0];
        genomeData.enq(d_converted);
	endrule

	rule updateKmer;
	    genomeData.deq;
	    Bit#(2) data = genomeData.first;

        Bit#(32) data_extended = zeroExtend(data);

		// $display("kmer : %b", kmer); 
		// $display("left shift kmer : %b", (kmer << 2)); 
		// $display("right || kmer : %b", (kmer << 2) | zeroExtend(data)); 
		// $display("zero : %b", data_extended); 

		kmer <= (kmer << 2) | zeroExtend(data);
		count <= count + 1;

		if(count >= 16) begin
			Bit#(32) sub_kmer = zeroExtend(kmer[15:0]);
			if (sub_kmer < min) min <= sub_kmer;
		end

		$display("kmer and min and count: %b %b %d \n", kmer, min[15:0], count);
	endrule
    
	rule sendDataToHost;
		$display("send data");
		let r <- pcie.dataReq;
		let a = r.addr;
		let offset = (a>>2);
        if (offset == 0) begin
			pcie.dataSend(r, min);
		end else begin
		    $display( "Wrong Request from channel %d", r.addr);
		end
	endrule
endmodule
