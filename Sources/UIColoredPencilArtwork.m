#import "UIColoredPencilArtwork.h"
#if UICOLORPANEL_ENABLE_PENCILS
#include <math.h>
#include <stdint.h>
#include <string.h>

// The palette's selected colors are color-managed separately. These sRGB
// pigments describe the appearance of the lead and lacquer under neutral light.
static const struct {
    const char *name;
    uint8_t rgb[3];
    const uint8_t *lacquerOverride;
} UIColorPanelPencilPigments[] = {
    {"Licorice", {0, 0, 0}, NULL},
    {"Lead", {22, 22, 22}, NULL},
    {"Tungsten", {49, 49, 49}, NULL},
    {"Iron", {74, 74, 74}, NULL},
    {"Steel", {100, 100, 100}, NULL},
    {"Tin", {125, 125, 125}, NULL},
    {"Nickel", {126, 126, 126}, NULL},
    {"Aluminum", {152, 152, 152}, NULL},
    {"Magnesium", {178, 178, 178}, NULL},
    {"Silver", {203, 203, 203}, NULL},
    {"Mercury", {229, 229, 229}, NULL},
    {"Snow", {255, 255, 255}, NULL},
    {"Cayenne", {126, 1, 1}, NULL},
    {"Mocha", {126, 62, 1}, NULL},
    {"Asparagus", {126, 126, 1}, NULL},
    {"Fern", {62, 126, 1}, NULL},
    {"Clover", {0, 126, 0}, NULL},
    {"Moss", {0, 126, 61}, NULL},
    {"Teal", {0, 126, 126}, NULL},
    {"Ocean", {0, 62, 126}, NULL},
    {"Midnight", {0, 1, 126}, NULL},
    {"Eggplant", {62, 1, 126}, NULL},
    {"Plum", {126, 1, 126}, NULL},
    {"Maroon", {126, 1, 62}, NULL},
    {"Maraschino", {255, 1, 1}, (const uint8_t[]){255, 54, 54}},
    {"Tangerine", {255, 126, 1}, (const uint8_t[]){255, 113, 54}},
    {"Lemon", {255, 254, 1}, NULL},
    {"Lime", {126, 254, 1}, NULL},
    {"Spring", {0, 254, 0}, NULL},
    {"SeaFoam", {0, 254, 126}, NULL},
    {"Turquoise", {0, 254, 254}, NULL},
    {"Aqua", {0, 127, 254}, NULL},
    {"Blueberry", {0, 1, 254}, NULL},
    {"Grape", {126, 1, 254}, NULL},
    {"Magenta", {255, 1, 255}, NULL},
    {"Strawberry", {255, 1, 127}, NULL},
    {"Salmon", {255, 101, 101}, NULL},
    {"Cantaloupe", {255, 202, 101}, NULL},
    {"Banana", {255, 254, 101}, NULL},
    {"Honeydew", {203, 254, 101}, NULL},
    {"Flora", {100, 254, 100}, NULL},
    {"Spindrift", {100, 254, 202}, NULL},
    {"Ice", {100, 254, 254}, NULL},
    {"Sky", {100, 202, 254}, NULL},
    {"Orchid", {100, 101, 254}, NULL},
    {"Lavender", {203, 101, 254}, NULL},
    {"Bubblegum", {255, 101, 255}, NULL},
    {"Carnation", {255, 110, 207}, NULL},
};

// BINMAP-ADAPT: UIColorPanelPencilColorsForColumn manifest=reimpl/pencil_api_manifest.json
static inline void UIColorPanelPencilColorsForColumn(NSUInteger index, NSUInteger x,
                                                      uint8_t tipRGB[3], uint8_t barrelRGB[3]) {
    // Each profile spans the width of its own cross-section. The cylindrical
    // lacquer has a narrow white reflection on the lit side of the barrel.
    static const uint8_t barrelDiffuse[80] = {
        104, 131, 131, 131, 131, 131, 131, 129, 132, 135, 135, 139, 140, 143, 145, 148,
        151, 153, 156, 159, 161, 165, 167, 170, 174, 177, 180, 183, 185, 188, 191, 193,
        197, 200, 203, 205, 209, 212, 216, 219, 223, 227, 229, 233, 238, 232, 225, 223,
        221, 221, 220, 222, 223, 223, 225, 229, 241, 244, 240, 238, 236, 235, 233, 231,
        229, 227, 224, 222, 219, 217, 214, 210, 207, 203, 198, 193, 187, 180, 175, 155,
    };
    static const uint8_t barrelReflection[80] = {
          2,   2,   2,   2,   2,   2,   2,   3,   3,   3,   3,   2,   2,   2,   2,   2,
          2,   2,   2,   2,   2,   3,   3,   3,   2,   2,   2,   2,   3,   3,   3,   3,
          3,   3,   3,   3,   3,   3,   3,   3,   3,   3,   3,   3,   2,   9,  18,  21,
         24,  24,  24,  24,  24,  24,  21,  17,   6,   2,   3,   3,   3,   3,   3,   3,
          3,   3,   3,   3,   3,   3,   3,   3,   3,   3,   3,   3,   2,   2,   2,   2,
    };
    static const uint8_t leadDiffuse[80] = {
        136, 136, 136, 136, 135, 134, 133, 135, 138, 140, 143, 145, 148, 151, 154, 157,
        161, 164, 167, 171, 174, 177, 180, 184, 187, 190, 193, 196, 199, 202, 205, 208,
        211, 214, 217, 219, 222, 225, 228, 230, 232, 234, 236, 238, 240, 242, 243, 244,
        245, 246, 247, 248, 249, 251, 252, 253, 252, 252, 251, 251, 249, 248, 247, 246,
        244, 243, 241, 239, 236, 233, 230, 226, 222, 218, 214, 210, 206, 192, 178, 165,
    };
    const uint8_t *lead = UIColorPanelPencilPigments[index].rgb;
    const uint8_t *lacquer = UIColorPanelPencilPigments[index].lacquerOverride;
    if (!lacquer) lacquer = lead;
    for (NSUInteger c = 0; c < 3; c++) {
        unsigned tip = 3 + (leadDiffuse[x] * lead[c] + 127) / 255;
        tipRGB[c] = (uint8_t)MIN(tip, 255u);
        barrelRGB[c] = (uint8_t)(barrelReflection[x] + (barrelDiffuse[x] * lacquer[c] + 127) / 255);
    }
}

// BINMAP-ADAPT: UIColorPanelPencilArtwork manifest=reimpl/pencil_api_manifest.json
UIImage * UIColorPanelPencilArtwork(NSString *name) {
    static NSCache<NSString *, UIImage *> *cache;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ cache = [NSCache new]; });
    UIImage *cached = [cache objectForKey:name];
    if (cached) return cached;

    // A host may supply the named list in a different order.
    const char *suffix = name.UTF8String;
    const NSUInteger count = sizeof(UIColorPanelPencilPigments) / sizeof(UIColorPanelPencilPigments[0]);
    NSUInteger index = 0;
    while (index < count && strcmp(suffix, UIColorPanelPencilPigments[index].name) != 0) index++;
    if (index == count) return nil;

    enum { width = 80, height = 576 };
    // Side lighting across the sharpened wood, in encoded sRGB.
    static const uint8_t woodStops[][3] = {
        {185,152,117}, {185,149,111}, {191,159,122}, {201,173,137},
        {207,180,147}, {216,191,162}, {223,197,167}, {231,208,175},
        {235,213,177}, {241,220,183}, {243,223,185}, {244,223,182},
        {244,223,181}, {240,219,178}, {231,207,165}, {218,192,155}, {198,175,144}
    };
    // Coverage along a resampled edge, at quarter-pixel intervals.
    static const uint8_t edgeCoverage[] = {
        0, 0, 2, 3, 4, 3, 0, 0, 0, 0, 0, 27, 74, 128,
        184, 229, 254, 255, 255, 255, 255, 253, 252, 254, 255
    };
    // The filtered cone has an outer fringe below 2% opacity. Its left and
    // right contours retain a scanline-dependent subpixel offset (1/64 px).
    // These offsets were traced jointly across the 48 source silhouettes.
    static const int8_t fringeOffsets[113][2] = {
        {0,0}, {0,-3}, {6,5}, {0,0}, {0,0}, {7,15}, {0,6}, {0,0}, {13,0},
        {-5,2}, {0,-10}, {0,0}, {-5,-5}, {-4,-7}, {0,0}, {0,0}, {0,-2}, {5,4},
        {0,0}, {0,0}, {6,15}, {2,5}, {0,0}, {12,0}, {0,2}, {0,-10}, {0,0},
        {-5,-6}, {-3,-7}, {0,0}, {0,0}, {0,-3}, {5,5}, {0,0}, {0,0}, {7,14},
        {2,7}, {0,0}, {12,0}, {0,2}, {0,-10}, {0,0}, {-6,-7}, {-7,-8}, {0,0},
        {-10,-3}, {2,5}, {0,0}, {0,12}, {3,0}, {-9,0}, {0,0}, {-3,-3}, {-12,0},
        {0,0}, {-7,-4}, {-3,5}, {0,0}, {0,-10}, {4,-2}, {9,0}, {0,0}, {8,-8},
        {1,0}, {0,0}, {4,-4}, {-3,-1}, {0,0}, {-2,-11}, {-1,-2}, {0,0}, {0,0},
        {4,2}, {9,0}, {0,0}, {17,2}, {6,4}, {0,0}, {15,0}, {3,-3}, {0,0},
        {-10,0}, {0,1}, {0,7}, {0,0}, {5,-4}, {0,3}, {0,0}, {1,0}, {7,8},
        {0,0}, {-4,0}, {-6,1}, {0,0}, {-9,0}, {0,-5}, {0,3}, {-14,0}, {0,0},
        {0,7}, {0,0}, {-9,0}, {0,1}, {0,-4}, {0,0}, {0,0}, {0,0}, {0,0},
        {0,0}, {0,0}, {0,0}, {0,0}, {0,0},
    };
    // The raised lacquer lip reflects light just below the cut. Each pair is
    // its paint contribution (percent) and reflected light, spaced half a pixel.
    static const int8_t lacquerLip[][2] = {
        {0,0}, {-3,0}, {-2,-4}, {11,-7}, {49,-4}, {95,6}, {111,17},
        {103,7}, {93,4}, {94,-2}, {100,-1}, {101,0}, {100,0}
    };
    uint8_t lead[width][3], barrel[width][3];
    for (NSUInteger x = 0; x < width; x++)
        UIColorPanelPencilColorsForColumn(index, x, lead[x], barrel[x]);

    // Interpolate a repeatable field of narrow, lengthwise wood fibers.
    uint8_t fibers[32][96];
    uint32_t state = 0x73ad85f9u ^ (uint32_t)(index + 1);
    for (NSUInteger y = 0; y < 32; y++) {
        for (NSUInteger x = 0; x < 96; x++) {
            state = state * 1664525u + 1013904223u;
            fibers[y][x] = (uint8_t)(state >> 24);
        }
    }

    NSMutableData *data = [NSMutableData dataWithLength:width * height * 4];
    uint8_t *pixels = data.mutableBytes;
    for (NSUInteger x = 0; x < width; x++) {
        double dx = x + 0.5 - 40;
        // Elliptical sections where the exposed lead, wood and lacquer meet.
        double leadEnd = 43.9 + 2.25 * sqrt(fmax(0, 1 - dx * dx / (19 * 19)));
        double section = sqrt(1 - dx * dx / (40 * 40));
        double woodEnd = 110.5 + 4.9 * section;
        double barrelEnd = 571.8 + 4.5 * section;

        for (NSUInteger y = 0; y < height; y++) {
            uint8_t *pixel = pixels + 4 * (y * width + x);
            double py = y + 0.5;
            double rgb[3] = {barrel[x][0], barrel[x][1], barrel[x][2]};
            double coverage = 255;
            if (py < 120) {
                BOOL inLead = py < 44;
                double radius = inLead ? 7.17 + 0.2663 * py : 5.65 + 0.304 * py;
                // The source artwork has a small registration shift across the twelve columns.
                double center = (inLead ? 40 : 40.39 - 0.0047 * py) - (index % 12) * 0.0125;
                double u = (x + 0.5 - center) / radius;
                double distance = radius - fabs(x + 0.5 - center);
                double edge = fmin(24, fmax(0, (distance + 3.25) * 4));
                NSUInteger stop = MIN((NSUInteger)edge, 23u);
                coverage = edgeCoverage[stop] + (edge - stop) * (edgeCoverage[stop + 1] - edgeCoverage[stop]);
                if (y < 113 && distance < -2.6) {
                    double contour = -2.95 + fringeOffsets[y][x >= 40] / 64.0;
                    coverage = fmax(0, 0.5 + (distance - contour) * 6);
                }
                if (y >= 113) coverage = 255;
                if (coverage < 0.5) continue;

                u = fmax(-1, fmin(1, u));
                double woodAmount = fmin(1, fmax(0, py - leadEnd + 0.5));
                double lipPosition = fmax(0, fmin(12, (py - woodEnd + 2) * 2));
                NSUInteger lip = MIN((NSUInteger)lipPosition, 11u);
                double mix = lipPosition - lip;
                double paintAmount = (lacquerLip[lip][0] + mix * (lacquerLip[lip + 1][0] - lacquerLip[lip][0])) / 100;
                double reflected = lacquerLip[lip][1] + mix * (lacquerLip[lip + 1][1] - lacquerLip[lip][1]);
                double tipPosition = fmin(79, fmax(0, (u + 1) * 40 - 0.5));
                NSUInteger tip = MIN((NSUInteger)tipPosition, 78u);

                double woodPosition = (u + 1) * 8;
                NSUInteger wood = MIN((NSUInteger)woodPosition, 15u);
                double grain = 0;
                if (woodAmount > 0 && lipPosition < 12) {
                    double fx = 46 + dx * 0.54 + u * 20 + 0.7 * sin(0.08 * py + 5 * u);
                    double fy = py * 0.21;
                    NSUInteger ix = (NSUInteger)fx, iy = (NSUInteger)fy;
                    double tx = fx - ix, ty = fy - iy;
                    double upper = fibers[iy][ix] * (1 - tx) + fibers[iy][ix + 1] * tx;
                    double lower = fibers[iy + 1][ix] * (1 - tx) + fibers[iy + 1][ix + 1] * tx;
                    grain = (upper * (1 - ty) + lower * ty - 127.5) / 8.0;
                    grain += 3.5 * sin(32 * u + 0.045 * py + sin(8 * u));
                }
                static const double grainStrength[] = {0.56, 0.93, 1.25};
                for (NSUInteger c = 0; c < 3; c++) {
                    double tipColor = lead[tip][c] + (tipPosition - tip) * (lead[tip + 1][c] - lead[tip][c]);
                    if (y < 2) {
                        double flatTip = 3 + UIColorPanelPencilPigments[index].rgb[c] * (0.59 - 0.025 * u);
                        tipColor = y == 0 ? flatTip : 0.53 * tipColor + 0.47 * flatTip;
                    }
                    double woodColor = woodStops[wood][c] + (woodPosition - wood) * (woodStops[wood + 1][c] - woodStops[wood][c]);
                    woodColor += grain * grainStrength[c];
                    double color = tipColor + woodAmount * (woodColor - tipColor);
                    rgb[c] = color + paintAmount * (barrel[x][c] - color) + reflected;
                }
                if (y == 0) coverage *= fmin(1, 1.6 - 0.92 * u * u);
            } else {
                // The shaft narrows by a fraction of a pixel towards its base.
                if (x == 0) coverage *= 1 - 0.20 * fmin(1, fmax(0, (py - 400) / 170));
                if (x == width - 1) coverage *= 1 - 0.43 * fmin(1, fmax(0, (py - 255) / 285));
                if (y >= 571) coverage *= fmin(1, fmax(0, barrelEnd - py + 0.5));
            }
            pixel[3] = (uint8_t)lround(coverage);
            for (NSUInteger c = 0; c < 3; c++)
                pixel[c] = (uint8_t)lround(fmin(255, fmax(0, rgb[c])) * pixel[3] / 255);
        }
    }

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGImageRef bitmap = CGImageCreate(width, height, 8, 32, width * 4, space,
                                      kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                      provider, NULL, true, kCGRenderingIntentDefault);
    UIImage *image = bitmap ? [UIImage imageWithCGImage:bitmap scale:1 orientation:UIImageOrientationUp] : nil;
    if (bitmap) CGImageRelease(bitmap);
    CGColorSpaceRelease(space);
    CGDataProviderRelease(provider);
    if (image) [cache setObject:image forKey:name];
    return image;
}
#endif
