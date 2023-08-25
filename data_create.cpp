#include <iostream>
#include <fstream>
#include <ctime>
#include <cstdlib>

int main() {
    // 랜덤 시드 초기화
    std::srand(static_cast<unsigned int>(std::time(nullptr)));

    // 10,000개의 랜덤 유전자 서열 생성
    std::string genome;
    for (int i = 0; i < 1000; ++i) {
        int randomChoice = std::rand() % 4;
        switch (randomChoice) {
            case 0:
                genome += 'A';
                break;
            case 1:
                genome += 'C';
                break;
            case 2:
                genome += 'G';
                break;
            case 3:
                genome += 'T';
                break;
        }
    }

    // 파일에 저장
    std::ofstream outFile("genome_sequence.txt");
    if (outFile.is_open()) {
        outFile << genome;
        outFile.close();
        std::cout << "유전자 서열이 'genome_sequence.txt' 파일에 저장되었습니다." << std::endl;
    } else {
        std::cerr << "파일을 열 수 없습니다." << std::endl;
    }

    return 0;
}
