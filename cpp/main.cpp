#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <bitset>
#include <iostream>
#include <algorithm>

#include "bdbmpcie.h"
#include "dmasplitter.h"

#define F_NAME_GENOME "../data/genome.txt"
#define SIZE 640

std::bitset<2> genome_data[SIZE*SIZE];
int idx = 0;

void init() {
    FILE* file_genome = fopen(F_NAME_GENOME, "r");
    char genome[SIZE*SIZE];

    while (fscanf(file_genome, "%c", &genome[idx]) != EOF && idx < SIZE*SIZE) {
        char c = genome[idx];
        std::bitset<2> bits; // 2비트 bitset

        switch (c) {
            case 'A': genome_data[idx] = std::bitset<2>("00"); break;
            case 'T': genome_data[idx] = std::bitset<2>("01"); break;
            case 'C': genome_data[idx] = std::bitset<2>("10"); break;
            case 'G': genome_data[idx] = std::bitset<2>("11"); break;
        }

        idx++;
    }

    printf("genome data : %d, idx size : %d", genome_data, idx);
    fclose(file_genome);

}

std::string convertToDNA(const std::bitset<32>& bits) {
    std::string dna = "";
    for (int i = 0; i < 32; i += 2) {
        if (bits[i] == 0 && bits[i + 1] == 0) {
            dna += "A";
        } else if (bits[i] == 0 && bits[i + 1] == 1) {
            dna += "T";
        } else if (bits[i] == 1 && bits[i + 1] == 0) {
            dna += "C";
        } else if (bits[i] == 1 && bits[i + 1] == 1) {
            dna += "G";
        }
    }
    reverse(dna.begin(), dna.end());
    return dna;
}

int main(int argc, char** argv) {
    init();

    BdbmPcie* pcie = BdbmPcie::getInstance();

    printf( "Starting Data Sending \n" );
    /* Send Data To Host */
    for (int i = 0; i < idx; i += 16) {
        std::bitset<32> dataToSend;
        for (int j = 0; j < 16; ++j) {
            dataToSend[j*2] = genome_data[i+j][0];
            dataToSend[j*2+1] = genome_data[i+j][1];
        }
        printf("turn %d, send genome data : %s\n", i/16, dataToSend.to_string().c_str());
        pcie->userWriteWord(0, dataToSend.to_ulong());

        // std::bitset<32> dataReceived = pcie->userReadWord(0);
        // std::cout << "data receive : " << dataReceived << std::endl;
    }
    printf( "Data Sending is Done \n" );

    /* Receive Data From FPGA */
    printf( "Starting Result Receiving \n" );
    std::bitset<32> data = pcie->userReadWord(0);
    std::bitset<32> sub_data;
    for (int i = 0; i < 32; i++) {
        sub_data[i] = data[i];
    }
    std::string dna = convertToDNA(sub_data);
    printf("%s \n", dna.c_str());
    printf( "\nData Receiving is Done \n" );
    // printf("Starting Result Receiving \n");

    // while (idx < 200) {
    //     std::bitset<32> data = pcie->userReadWord(0);
    //     std::bitset<14> sub_data;
    //     for (int i = 0; i < 14; i++) {
    //         sub_data[i] = data[i];
    //     }
    //     std::string dna = convertToDNA(sub_data);
    //     printf("%s \n", dna.c_str());
    //     idx += 1;
    //     std::cout << "idx : " << idx << "dna : " << dna << std::endl;

    //     sleep(0.1);
    // }

    // printf("\nData Receiving is Done \n");
    return 0;
}
