/*
	Copyright 2024 Efabless Corp.

	Author: Efabless Corp. (ip_admin@efabless.com)

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	    http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.

*/

`timescale          1ns/1ps
`default_nettype    none

module EF_WDT32 (
		input wire          clk,
		input wire          rst_n,
		input wire          WDTEN, // = 1 Enable
		input wire [31:0]   WDTLOAD, //Reload Value

		output reg         WDTTO, //TimeOut
		output reg [31:0]   WDTMR //Timer

);

	//assign	WDTTO = WDTEN & (WDTMR == 32'd0);
	
	// WDTimer
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n) begin
			WDTMR <= 32'h0000_0000;
			WDTTO <= 1;
		end
		else if(WDTEN == 1'b0)
			WDTMR <= WDTLOAD;
		else if(WDTTO == 1'b1)
			WDTMR <= WDTLOAD;
		else 
			WDTMR <= WDTMR - 32'd1;
		
		WDTTO <= WDTEN & (WDTMR == 32'd0);
	end

endmodule
