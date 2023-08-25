import FIFO::*;
import FIFOF::*;
import BRAM::*;
import Clocks::*;
import Vector::*;
import BRAMFIFO::*;

import PcieCtrl::*;

interface HwMainIfc;
endinterface

typedef 4096 Matrix_Size;

module mkHwMain#(PcieUserIfc pcie) (HwMainIfc);
	Vector#(16, FIFO#(Bit#(64))) inQ4 <- replicateM(mkSizedFIFO(32));
    Vector#(8, FIFO#(Bit#(64))) inQ3 <- replicateM(mkSizedFIFO(32));
    Vector#(4, FIFO#(Bit#(64))) inQ2 <- replicateM(mkSizedFIFO(32));
    Vector#(2, FIFO#(Bit#(64))) inQ1 <- replicateM(mkSizedFIFO(32));
    Vector#(16, FIFO#(Bit#(32))) mergeQ <- replicateM(mkSizedFIFO(32));
    Vector#(8, FIFO#(Bit#(32))) mergeQ2 <- replicateM(mkSizedFIFO(32));
    Vector#(4, FIFO#(Bit#(32))) mergeQ3 <- replicateM(mkSizedFIFO(32));
    Vector#(2, FIFO#(Bit#(32))) mergeQ4 <- replicateM(mkSizedFIFO(32));
	FIFO#(Bit#(32)) mergeQ5 <- mkSizedFIFO(32);
	FIFO#(Bit#(64)) nextQ <- mkSizedFIFO(32);
	
	FIFOF#(Bit#(32)) kmer <- mkSizedFIFOF(16);
	Reg#(Bit#(32)) min <- mkReg(32'hFFFFFFFF);
	Reg#(Bit#(32)) tmp_min <- mkReg(0);

    Reg#(Bit#(64)) v <- mkReg(0);
    FIFO#(Bit#(32)) inQ <- mkSizedFIFO(64);
	FIFOF#(Bit#(32)) outQ <- mkSizedFIFOF(64);
	Reg#(Bit#(256)) count <- mkReg(0);

	Reg#(Bit#(256)) cnt <- mkReg(0);

	Reg#(Bit#(256)) cyc <- mkReg(0);

	Reg#(Bit#(2)) v_assigned <- mkReg(0);
	Reg#(Bit#(256)) outQ_count <- mkReg(0);
	Reg#(Bit#(256)) start_cycle <- mkReg(0);

	Reg#(Bool) merge6Executed <- mkReg(False);

	rule incCycle;
		cyc <= cyc + 1;
	endrule

	rule detectVAssignment(v_assigned == 1);
		v_assigned <= 2;
		start_cycle <= cyc;
		$display("start cycle : %d", start_cycle);
	endrule

	rule displayCyclesWhenOutQIsThree(outQ_count == 7);
		$display("cycle speed: %d, cyc : %d, start_cycle : %d", cyc - start_cycle, cyc, start_cycle);
		$display("fin min : %b", min);
		outQ_count <= outQ_count + 1; 
	endrule
	
    rule receiveData;
		let w <- pcie.dataReceive;
		Bit#(20) a = w.addr;
		Bit#(32) d = w.data;
		inQ.enq(d);
		cnt <= cnt + 1;
		$display("cnt : %d", cnt);
    endrule

    rule minimizer;
		inQ.deq;
		Bit#(64) tmp = {inQ.first(), v[63:32]};
		if(v_assigned == 0) begin
			v_assigned <= 1;
		end
		$display("mini");
		v <= tmp;
		nextQ.enq(tmp);
	endrule

	rule devide1;
		nextQ.deq;
		inQ1[0].enq(nextQ.first);
		inQ1[1].enq(nextQ.first);
	endrule

	for (Integer i=0;i<2;i=i+1) begin
		rule devide2;
			inQ2[i*2].enq(inQ1[i].first);
			inQ2[i*2+1].enq(inQ1[i].first);
			inQ1[i].deq;
		endrule
	end

	for (Integer i=0;i<4;i=i+1) begin
		rule devide3;
			inQ3[i*2].enq(inQ2[i].first);
			inQ3[i*2+1].enq(inQ2[i].first);
			inQ2[i].deq;
		endrule
	end

	for (Integer i=0;i<8;i=i+1) begin
		rule devide4;
			inQ4[i*2].enq(inQ3[i].first);
			inQ4[i*2+1].enq(inQ3[i].first);
			inQ3[i].deq;
		endrule
	end

	for (Integer i=0; i<16; i=i+1) begin
		rule merge1;
			inQ4[i].deq;
			Bit#(32) t = inQ4[i].first[i*2+31:i*2];
			// kmer.enq(t);
			mergeQ[i].enq(t);
			// merge1Count <= merge1Count + 1;
		endrule
	end

	for(Integer i=0;i<8;i=i+1) begin
		rule merge2;
			if(mergeQ[i*2].first < mergeQ[i*2+1].first) begin
				mergeQ2[i].enq(mergeQ[i*2].first);
			end
			else begin
				mergeQ2[i].enq(mergeQ[i*2+1].first);
			end
			mergeQ[i*2].deq;
			mergeQ[i*2+1].deq;
		endrule
	end

	for(Integer i=0;i<4;i=i+1) begin
		rule merge3;
			if(mergeQ2[i*2].first < mergeQ2[i*2+1].first) begin
				mergeQ3[i].enq(mergeQ2[i*2].first);
			end
			else begin
				mergeQ3[i].enq(mergeQ2[i*2+1].first);
			end
			mergeQ2[i*2].deq;
			mergeQ2[i*2+1].deq;	
		endrule
	end

	for(Integer i=0;i<2;i=i+1) begin
		rule merge4;
			if(mergeQ3[i*2].first < mergeQ3[i*2+1].first) begin
				mergeQ4[i].enq(mergeQ3[i*2].first);
			end
			else begin
				mergeQ4[i].enq(mergeQ3[i*2+1].first);
			end
			mergeQ3[i*2].deq;
			mergeQ3[i*2+1].deq;	
		endrule
	end

	rule merge5;
		if(mergeQ4[0].first < mergeQ4[1].first) begin
			mergeQ5.enq(mergeQ4[0].first);
		end
		else begin
			mergeQ5.enq(mergeQ4[1].first);
		end
		mergeQ4[0].deq;
		mergeQ4[1].deq;	
	endrule

	rule merge6;
		tmp_min <= mergeQ5.first;
		mergeQ5.deq;

		if(tmp_min < min && tmp_min != 0) begin
			min <= tmp_min;
		end

		outQ.enq(min);
		outQ_count <= outQ_count + 1;

		merge6Executed <= True;

		$display("outQ_count : %b, min : %b", outQ_count, min);
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
