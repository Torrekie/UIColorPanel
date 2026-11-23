#import <Foundation/Foundation.h>

#ifndef UICOLORPANEL_ENABLE_PENCILS
#define UICOLORPANEL_ENABLE_PENCILS 1
#endif

// Numeric values and masks correspond to NSColorPanelMode / NSColorPanelOptions.
typedef NS_ENUM(NSInteger, UIColorPanelMode) {
    UIColorPanelModeNone = -1,
    UIColorPanelModeGray = 0,
    UIColorPanelModeRGB = 1,
    UIColorPanelModeCMYK = 2,
    UIColorPanelModeHSB = 3,
    UIColorPanelModeCustomPalette = 4,
    UIColorPanelModeColorList = 5,
    UIColorPanelModeWheel = 6,
    UIColorPanelModeCrayon = 7,
    // With Pencils disabled, requests for Crayon and its mask select Grid.
    UIColorPanelModeGrid = 8,
    // Source-compatible convenience names from the first kit version.
    UIColorPanelModeSliders = UIColorPanelModeRGB,
    UIColorPanelModePalettes = UIColorPanelModeColorList,
    UIColorPanelModeImage = UIColorPanelModeCustomPalette,
    UIColorPanelModePencils = UIColorPanelModeCrayon
};

typedef NS_OPTIONS(NSUInteger, UIColorPanelOptions) {
    UIColorPanelGrayModeMask = 0x00000001,
    UIColorPanelRGBModeMask = 0x00000002,
    UIColorPanelCMYKModeMask = 0x00000004,
    UIColorPanelHSBModeMask = 0x00000008,
    UIColorPanelCustomPaletteModeMask = 0x00000010,
    UIColorPanelColorListModeMask = 0x00000020,
    UIColorPanelWheelModeMask = 0x00000040,
    UIColorPanelCrayonModeMask = 0x00000080,
    UIColorPanelGridModeMask = 0x00000100,
    UIColorPanelAllModesMask = 0x0000ffff
};
