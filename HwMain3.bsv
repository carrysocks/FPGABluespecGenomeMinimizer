import FIFO::*;
import BRAM::*;
import Clocks::*;
import Vector::*;
import BRAMFIFO::*;

import PcieCtrl::*;

interface HwMainIfc;
endinterface

typedef 4096 Matrix_Size;

module mkHwMain#(PcieUserIfc pcie) (HwMainIfc);
	Vector#(16, FIFO#(Bit#(64))) inQ4 <- replicateM(mkSizedFIFO(64));
    Vector#(8, FIFO#(Bit#(64))) inQ3 <- replicateM(mkSizedFIFO(64));
    Vector#(4, FIFO#(Bit#(64))) inQ2 <- replicateM(mkSizedFIFO(64));
    Vector#(2, FIFO#(Bit#(64))) inQ1 <- replicateM(mkSizedFIFO(64));
    Vector#(16, FIFO#(Bit#(32))) mergeQ <- replicateM(mkSizedFIFO(64));
    Vector#(8, FIFO#(Bit#(32))) mergeQ2 <- replicateM(mkSizedFIFO(64));
    Vector#(4, FIFO#(Bit#(32))) mergeQ3 <- replicateM(mkSizedFIFO(64));
    Vector#(2, FIFO#(Bit#(32))) mergeQ4 <- replicateM(mkSizedFIFO(64));
	FIFO#(Bit#(32)) mergeQ5 <- mkSizedFIFO(64);
	FIFO#(Bit#(64)) nextQ <- mkSizedFIFO(64);
	
	Reg#(Bit#(32)) kmer <- mkReg(0);
	Reg#(Bit#(32)) min <- mkReg(32'hFFFFFFFF);
	Reg#(Bit#(32)) tmp_min <- mkReg(0);

    Reg#(Bit#(64)) v <- mkReg(0);
    FIFO#(Bit#(32)) inQ <- mkSizedFIFO(64);
	FIFO#(Bit#(32)) outQ <- mkSizedFIFO(64);
	Reg#(Bit#(64)) count <- mkReg(0);
	Reg#(Bit#(64)) count1 <- mkReg(0);
	Reg#(Bit#(64)) count2 <- mkReg(0);
	Reg#(Bit#(64)) merge1Count <- mkReg(0);
	Reg#(Bit#(64)) merge2Count <- mkReg(0);
	Reg#(Bit#(64)) merge3Count <- mkReg(0);
	Reg#(Bit#(64)) merge4Count <- mkReg(0);
	Reg#(Bit#(64)) merge5Count <- mkReg(0);
	Reg#(Bit#(64)) merge6Count <- mkReg(0);

	Reg#(Bit#(32)) q_cnt <- mkReg(0);
	Reg#(Bit#(32)) cnt <- mkReg(0);
	
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
		v <= tmp;
		count <= count + 1;
		nextQ.enq(tmp);
		$display("count : %d", count);
	endrule

	rule devide1(count >= 2);
		nextQ.deq;
		inQ1[0].enq(nextQ.first);
		inQ1[1].enq(nextQ.first);
		count1 <= count1 + 1;
		$display("count1 : %d", count1);
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

	for (Integer i=0;i<16;i=i+1) begin
		rule merge1;
			inQ4[i].deq;
			Bit#(32) t = inQ4[i].first[(i*2)+31:i*2];
			mergeQ[i].enq(t);
		endrule
	end

	// rule merge1(count >= 2);
	// 	$display("merge process and count : %d", count);
	// 	for (Integer i=0; i<16; i=i+1) begin
	// 		Bit#(32) t = nextQ.first[i*2+31:i*2];
	// 		mergeQ[i].enq(t);
	// 	end

	// 	merge1Count <= merge1Count + 1;
	// 	$display("merge1Count : %d", merge1Count);
	// endrule

	rule merge2;
		for (Integer i=0; i<8; i=i+1) begin
			if(mergeQ[i*2].first < mergeQ[i*2+1].first) begin
				mergeQ2[i].enq(mergeQ[i*2].first);
			end
			else begin
				mergeQ2[i].enq(mergeQ[i*2+1].first);
			end
			mergeQ[i*2].deq;
			mergeQ[i*2+1].deq;
		end
	endrule

	rule merge3;
		for (Integer i=0; i<4; i=i+1) begin
			if(mergeQ2[i*2].first < mergeQ2[i*2+1].first) begin
				mergeQ3[i].enq(mergeQ2[i*2].first);
			end
			else begin
				mergeQ3[i].enq(mergeQ2[i*2+1].first);
			end
			mergeQ2[i*2].deq;
			mergeQ2[i*2+1].deq;	
		end
	endrule

	rule merge4;
		for (Integer i=0; i<2; i=i+1) begin
			if(mergeQ3[i*2].first < mergeQ3[i*2+1].first) begin
				mergeQ4[i].enq(mergeQ3[i*2].first);
			end
			else begin
				mergeQ4[i].enq(mergeQ3[i*2].first);
			end
			mergeQ3[i*2].deq;
			mergeQ3[i*2+1].deq;	
		end
	endrule

	rule merge5;
		if(mergeQ4[0].first < mergeQ4[1].first) begin
			mergeQ5.enq(mergeQ4[0].first);
		end
		else begin
			mergeQ5.enq(mergeQ4[1].first);
		end
		mergeQ4[0].deq;
		mergeQ4[1].deq;	

		// merge5Count <= merge5Count + 1;
		// $display("merge5Count : %d", merge5Count);
	endrule

	rule merge6;
		tmp_min <= mergeQ5.first;
		mergeQ5.deq;

		if(tmp_min < min) begin
			min <= tmp_min;
		end

		// outQ.enq(kmer);
		outQ.enq(min);
		merge6Count <= merge6Count + 1;
		$display("merge6Count : %d", merge6Count);
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
