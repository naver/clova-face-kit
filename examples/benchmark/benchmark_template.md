| Device                         | Mode     | Thread | FPS |    Total | Detector | Landmarker | Aligner | Estimator | Recognizer |  Mask Detector |
|--------------------------------|----------|-------:|----:|---------:|---------:|-----------:|--------:|----------:|-----------:|---------------:|
| Pixel 4<sup>1</sup>            | Accurate |      1 |  18 |  49.14ms |   6.88ms |    21.41ms |  0.80ms |    0.12ms |    15.78ms |         4.15ms |
|                                |          |      2 |  24 |  35.80ms |   5.66ms |    15.78ms |  0.82ms |    0.13ms |    10.23ms |         3.18ms |
|                                |          |      4 |  27 |  30.21ms |   5.39ms |    13.82ms |  0.93ms |    0.14ms |     7.09ms |         2.84ms |
|                                | Fast     |      1 |  26 |  32.25ms |   6.86ms |     4.43ms |  0.76ms |    0.12ms |    15.78ms |         4.30ms |
|                                |          |      2 |  33 |  24.23ms |   5.66ms |     4.00ms |  0.92ms |    0.13ms |    10.17ms |         3.35ms |
|                                |          |      4 |  37 |  20.53ms |   5.40ms |     3.95ms |  0.93ms |    0.13ms |     7.26ms |         2.86ms |
| Raspberry Pi 4<sup>2</sup>     | Accurate |      1 |   5 | 189.17ms |  22.22ms |    78.01ms |  1.45ms |    0.30ms |    71.92ms |        15.27ms |
|                                |          |      2 |   7 | 138.58ms |  17.70ms |    58.42ms |  1.37ms |    0.30ms |    50.37ms |        10.42ms |
|                                |          |      4 |   7 | 121.45ms |  16.82ms |    53.80ms |  1.44ms |    0.31ms |    40.82ms |         8.26ms |
|                                | Fast     |      1 |   7 | 121.38ms |  22.13ms |     9.30ms |  1.38ms |    0.30ms |    72.96ms |        15.31ms |
|                                |          |      2 |  10 |  88.34ms |  17.72ms |     8.02ms |  1.35ms |    0.30ms |    50.64ms |        10.31ms |
|                                |          |      4 |  12 |  76.45ms |  16.62ms |     8.27ms |  1.45ms |    0.30ms |    41.46ms |         8.35ms |
| LG CNS XID-600<sup>3</sup>     | Accurate |      1 |   3 | 303.48ms |  35.95ms |   149.06ms |  3.41ms |    0.39ms |    92.55ms |        22.12ms |
|                                |          |      2 |   5 | 189.60ms |  24.63ms |    93.27ms |  3.36ms |    0.39ms |    54.30ms |        13.65ms |
|                                |          |      4 |   5 | 240.40ms |  52.38ms |   100.53ms |  3.46ms |    0.38ms |    68.99ms |        14.66ms |
|                                | Fast     |      1 |   5 | 167.67ms |  35.63ms |    13.78ms |  3.47ms |    0.39ms |    92.32ms |        22.18ms |
|                                |          |      2 |   8 | 106.61ms |  24.76ms |    10.95ms |  3.37ms |    0.39ms |    53.46ms |        13.68ms |
|                                |          |      4 |   9 | 172.85ms |  64.72ms |    13.32ms |  3.55ms |    0.39ms |    74.04ms |        16.83ms |
| NXP 8MMINILPD4-EVK<sup>4</sup> | Accurate |      1 |   3 | 313.49ms |  36.85ms |   156.35ms |  3.65ms |    0.40ms |    93.90ms |        22.34ms |
|                                |          |      2 |   5 | 190.29ms |  24.65ms |    93.98ms |  3.63ms |    0.39ms |    53.99ms |        13.65ms |
|                                |          |      4 |   4 | 317.45ms |  83.51ms |   123.12ms |  3.67ms |    0.40ms |    87.66ms |        19.09ms |
|                                | Fast     |      1 |   5 | 169.25ms |  36.10ms |    14.19ms |  3.69ms |    0.40ms |    92.45ms |        22.42ms |
|                                |          |      2 |   9 | 106.84ms |  24.54ms |    10.98ms |  3.63ms |    0.40ms |    53.72ms |        13.57ms |
|                                |          |      4 |   8 | 179.67ms |  69.51ms |    14.11ms |  3.40ms |    0.40ms |    75.42ms |        16.83ms |

| Device / Feature Matching      | 1:100000 |  1:50000 | 1:10000 |  1:5000 | 1:1000 |
|--------------------------------|---------:|---------:|--------:|--------:|-------:|
| Pixel 4<sup>1</sup>            |  45.96ms |  19.87ms |  3.95ms |  2.05ms | 0.40ms |
| Raspberry Pi 4<sup>2</sup>     | 226.60ms | 114.76ms | 23.06ms | 14.07ms | 2.41ms |
| LG CNS XID-600<sup>3</sup>     | 419.14ms | 191.30ms | 38.25ms | 19.28ms | 3.95ms |
| NXP 8MMINILPD4-EVK<sup>4</sup> | 374.72ms | 198.17ms | 38.63ms | 19.20ms | 4.00ms |

<sup>1</sup> [Pixel 4](https://store.google.com/us/product/pixel_4_specs?hl=en-US): Qualcomm Snapdragon 855 (2.84 GHz + 1.78 GHz, 64-Bit 8-Core) + Android 10<br/>
<sup>2</sup> [Raspberry Pi 4](https://www.raspberrypi.org/products/raspberry-pi-4-model-b/specifications/): Broadcom BCM2711 Cortex-A72 (1.5GHz, 64-Bit 8-Core) + Ubuntu 20.04<br/>
<sup>3</sup> [XID-600](https://www.nxp.com/products/processors-and-microcontrollers/arm-processors/i-mx-applications-processors/i-mx-8-processors/i-mx-8m-mini-arm-cortex-a53-cortex-m4-audio-voice-video:i.MX8MMINI): i.MX 8M Mini Cortex-A53 (1.8GHz, 64-Bit 8-Core) + NXP i.MX Release Distro 4.14<br/>
<sup>4</sup> [NXP 8MMINILPD4-EVK](https://www.nxp.com/design/development-boards/i-mx-evaluation-and-development-boards/evaluation-kit-for-the-i-mx-8m-mini-applications-processor:8MMINILPD4-EVK): i.MX 8M Mini Cortex-A53 (1.8GHz, 64-Bit 4-Core) + NXP i.MX Release Distro 4.14<br/>
