//------------------------------------------------
//               Ch07_04.cpp
//------------------------------------------------

#include "stdafx.h"
#include <iostream>
#include <cstdint>
#include <random>
#include "Ch07_04.h"
#include "AlignedMem.h"

using namespace std;

void Init(uint8_t* x, size_t n, unsigned int seed)
{
    uniform_int_distribution<> ui_dist {5, 250};
    default_random_engine rng {seed};

    for (size_t i = 0; i < n; i++)
        x[i] = (uint8_t)ui_dist(rng);

    // Use known values for min & max (for test purposes)
    x[(n / 4) * 3 + 1] = 2;
    x[n / 4 + 11] = 3;
    x[n / 2] = 252;
    x[n / 2 + 13] = 253;
    x[n / 8 + 5] = 4;
    x[n / 8 + 7] = 254;
}

bool AvxCalcMinMaxU8Cpp(const uint8_t* x, size_t n, uint8_t* x_min, uint8_t* x_max)
{
    if (n == 0 || (n & 0x3f) != 0)
        return false;

    if (!AlignedMem::IsAligned(x, 16))
        return false;

    uint8_t x_min_temp = 0xff;
    uint8_t x_max_temp = 0;

    for (size_t i = 0; i < n; i++)
    {
        uint8_t val = *x++;

        if (val < x_min_temp)
            x_min_temp = val;
        else if (val > x_max_temp)
            x_max_temp = val;
    }

    *x_min = x_min_temp;
    *x_max = x_max_temp;
    return true;
}

void AvxCalcMinMaxU8()
{
    size_t n = c_NumElements;
    AlignedArray<uint8_t> x_aa(n, 16);
    uint8_t* x = x_aa.Data();

    Init(x, n, c_RngSeedVal);

    uint8_t x_min1 = 0, x_max1 = 0;
    uint8_t x_min2 = 0, x_max2 = 0;
    bool rc1 = AvxCalcMinMaxU8Cpp(x, n, &x_min1, &x_max1);
    bool rc2 = AvxCalcMinMaxU8_(x, n, &x_min2, &x_max2);

    cout << "\nResults for AvxCalcMinMaxU8\n";
    cout << "rc1: " << rc1 << "  x_min1: " << (int)x_min1;
    cout << "  x_max1: " << (int)x_max1 << '\n';
    cout << "rc2: " << rc1 << "  x_min2: " << (int)x_min2;
    cout << "  x_max2: " << (int)x_max2 << '\n';
}

int main()
{
    AvxCalcMinMaxU8();
    AvxCalcMinMaxU8_BM();
    return 0;
}
