#include <iostream>
#include <string>
#include <chrono> // 시간 측정을 위한 헤더
#include <algorithm>
#include <fstream> // 파일 입출력을 위한 헤더

using namespace std;

#define F_NAME_GENOME "../data/genome.txt"

int main() {

    std::string seq = "";

    // 파일에서 유전자 서열 읽기
    std::ifstream inFile(F_NAME_GENOME);
    if (inFile.is_open()) {
        getline(inFile, seq);
        inFile.close();
    } else {
        std::cerr << "파일을 열 수 없습니다." << std::endl;
        return 1; // 오류로 종료
    }

    std::string rev = seq;
    std::reverse(rev.begin(), rev.end());

    for (auto &ch : rev) {
        switch (ch) {
            case 'A': ch = 'T'; break;
            case 'T': ch = 'A'; break;
            case 'C': ch = 'G'; break;
            case 'G': ch = 'C'; break;
        }
    }

    const int Kmer = 32;
    const int M = 16;
    const int L = seq.size();

    // 시간 측정 시작
    auto start = std::chrono::high_resolution_clock::now();

    for (int i = 0; i <= L - Kmer; i++) {
        std::string sub_f = seq.substr(i, Kmer);
        std::string sub_r = rev.substr(L - Kmer - i, Kmer);

        std::string min = "ZZZZZZZZZZZZZ";
        for (int j = 0; j <= Kmer - M; j++) {
            std::string sub2 = sub_f.substr(j, M);
            if (sub2 < min) {
                min = sub2;
            }
            sub2 = sub_r.substr(j, M);
            if (sub2 < min) {
                min = sub2;
            }
        }
        // std::cout << sub_f << " " << min << std::endl;
    }

    // 시간 측정 종료 및 출력
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start);
    std::cout << "Elapsed time: " << duration.count() << " nanoseconds" << std::endl;

    return 0;
}
