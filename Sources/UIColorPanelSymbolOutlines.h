// Project-authored interface symbols on a shared 24-point drawing grid.
// These geometric paths do not contain extracted font outlines or Apple artwork.
// M/L/Q/C/Z build paths, E/R add ellipses/rounded rectangles, S/F stroke/fill.
#pragma once
#import <CoreGraphics/CoreGraphics.h>
typedef struct { char operation; CGFloat coordinates[6]; } UIColorPanelSymbolCommand;
typedef struct { const char *name; const UIColorPanelSymbolCommand *commands; unsigned long count; } UIColorPanelSymbolOutline;

static const UIColorPanelSymbolCommand UIColorPanelSymbolEllipsisCircle[] = {
    {'E',{2,2,20,20}}, {'S',{0}},
    {'E',{6.25,10.75,2.5,2.5}},
    {'E',{10.75,10.75,2.5,2.5}},
    {'E',{15.25,10.75,2.5,2.5}}, {'F',{0}}
};
static const UIColorPanelSymbolCommand UIColorPanelSymbolChevronDown[] = {
    {'M',{3.5,8}}, {'L',{12,16.5}}, {'L',{20.5,8}}, {'S',{0}}
};
static const UIColorPanelSymbolCommand UIColorPanelSymbolPlus[] = {
    {'M',{12,3}}, {'L',{12,21}},
    {'M',{3,12}}, {'L',{21,12}}, {'S',{0}}
};
static const UIColorPanelSymbolCommand UIColorPanelSymbolMinus[] = {
    {'M',{3,12}}, {'L',{21,12}}, {'S',{0}}
};
static const UIColorPanelSymbolCommand UIColorPanelSymbolXmark[] = {
    {'M',{4.5,4.5}}, {'L',{19.5,19.5}},
    {'M',{19.5,4.5}}, {'L',{4.5,19.5}}, {'S',{0}}
};
static const UIColorPanelSymbolCommand UIColorPanelSymbolTrash[] = {
    {'M',{4,6}}, {'L',{20,6}},
    {'M',{9,6}}, {'L',{9,3.5}},
    {'Q',{9,2.5,10,2.5}}, {'L',{14,2.5}},
    {'Q',{15,2.5,15,3.5}}, {'L',{15,6}},
    {'M',{6,6}}, {'L',{7.1,19.5}},
    {'Q',{7.2,21,8.7,21}}, {'L',{15.3,21}},
    {'Q',{16.8,21,16.9,19.5}}, {'L',{18,6}},
    {'M',{9.5,9.5}}, {'L',{10,17.5}},
    {'M',{14.5,9.5}}, {'L',{14,17.5}}, {'S',{0}}
};
static const UIColorPanelSymbolCommand UIColorPanelSymbolCheckmark[] = {
    {'M',{3,12.5}}, {'L',{9.2,18.5}}, {'L',{21,5.5}}, {'S',{0}}
};
static const UIColorPanelSymbolCommand UIColorPanelSymbolEllipsis[] = {
    {'E',{3,10.5,3,3}},
    {'E',{10.5,10.5,3,3}},
    {'E',{18,10.5,3,3}}, {'F',{0}}
};
static const UIColorPanelSymbolCommand UIColorPanelSymbolWheel[] = {
    {'E',{2,2,20,20}},
    {'M',{12,2}}, {'L',{12,22}},
    {'M',{3.34,7}}, {'L',{20.66,17}},
    {'M',{3.34,17}}, {'L',{20.66,7}}, {'S',{0}}
};
static const UIColorPanelSymbolCommand UIColorPanelSymbolSliders[] = {
    {'M',{3,5}}, {'L',{5.75,5}},
    {'M',{10.25,5}}, {'L',{21,5}},
    {'E',{5.75,2.75,4.5,4.5}},
    {'M',{3,12}}, {'L',{13.75,12}},
    {'M',{18.25,12}}, {'L',{21,12}},
    {'E',{13.75,9.75,4.5,4.5}},
    {'M',{3,19}}, {'L',{7.75,19}},
    {'M',{12.25,19}}, {'L',{21,19}},
    {'E',{7.75,16.75,4.5,4.5}}, {'S',{0}}
};
static const UIColorPanelSymbolCommand UIColorPanelSymbolPalette[] = {
    {'R',{2.5,2.5,7.5,7.5,1.25}},
    {'R',{14,2.5,7.5,7.5,1.25}},
    {'R',{2.5,14,7.5,7.5,1.25}},
    {'R',{14,14,7.5,7.5,1.25}}, {'S',{0}}
};
static const UIColorPanelSymbolCommand UIColorPanelSymbolImage[] = {
    {'R',{2,3,20,18,2.5}},
    {'M',{2.5,18}}, {'L',{8.3,12.5}}, {'L',{12.8,17}},
    {'L',{16.4,13.5}}, {'L',{21.5,18.5}}, {'S',{0}},
    {'E',{14.75,6.25,3.5,3.5}}, {'F',{0}}
};
static const UIColorPanelSymbolCommand UIColorPanelSymbolGrid[] = {
    {'R',{2,2,5,5,1}}, {'R',{9.5,2,5,5,1}}, {'R',{17,2,5,5,1}},
    {'R',{2,9.5,5,5,1}}, {'R',{9.5,9.5,5,5,1}}, {'R',{17,9.5,5,5,1}},
    {'R',{2,17,5,5,1}}, {'R',{9.5,17,5,5,1}}, {'R',{17,17,5,5,1}}, {'F',{0}}
};

static const UIColorPanelSymbolCommand UIColorPanelSymbolPencils[] = {
    {'M',{3,21}}, {'L',{4.5,14.5}}, {'L',{16.8,2.2}},
    {'Q',{18.2,.8,19.6,2.2}}, {'L',{21.8,4.4}},
    {'Q',{23.2,5.8,21.8,7.2}}, {'L',{9.5,19.5}}, {'Z',{0}},
    {'M',{14.5,4.5}}, {'L',{19.5,9.5}},
    {'M',{4.5,14.5}}, {'L',{9.5,19.5}},
    {'M',{6.8,16.8}}, {'L',{17,6.6}}, {'S',{0}},
    {'M',{3,21}}, {'L',{3.9,17.1}}, {'L',{6.9,20.1}}, {'Z',{0}}, {'F',{0}}
};
static const UIColorPanelSymbolCommand UIColorPanelSymbolEyedropper[] = {
    {'M',{13,6.5}}, {'L',{16.5,3}},
    {'C',{17.9,1.6,20.1,1.6,21.5,3}},
    {'C',{22.9,4.4,22.9,6.6,21.5,8}},
    {'L',{18,11.5}}, {'Z',{0}},
    {'M',{11.5,5}}, {'L',{19.5,13}},
    {'M',{13,8}}, {'L',{5,16}}, {'L',{3.5,20.5}},
    {'L',{8,19}}, {'L',{16,11}}, {'S',{0}}
};

static const UIColorPanelSymbolOutline UIColorPanelSymbolOutlines[] = {
    {"ellipsis.circle",UIColorPanelSymbolEllipsisCircle,sizeof(UIColorPanelSymbolEllipsisCircle)/sizeof(UIColorPanelSymbolEllipsisCircle[0])},
    {"chevron.down",UIColorPanelSymbolChevronDown,sizeof(UIColorPanelSymbolChevronDown)/sizeof(UIColorPanelSymbolChevronDown[0])},
    {"plus",UIColorPanelSymbolPlus,sizeof(UIColorPanelSymbolPlus)/sizeof(UIColorPanelSymbolPlus[0])},
    {"minus",UIColorPanelSymbolMinus,sizeof(UIColorPanelSymbolMinus)/sizeof(UIColorPanelSymbolMinus[0])},
    {"xmark",UIColorPanelSymbolXmark,sizeof(UIColorPanelSymbolXmark)/sizeof(UIColorPanelSymbolXmark[0])},
    {"trash",UIColorPanelSymbolTrash,sizeof(UIColorPanelSymbolTrash)/sizeof(UIColorPanelSymbolTrash[0])},
    {"checkmark",UIColorPanelSymbolCheckmark,sizeof(UIColorPanelSymbolCheckmark)/sizeof(UIColorPanelSymbolCheckmark[0])},
    {"ellipsis",UIColorPanelSymbolEllipsis,sizeof(UIColorPanelSymbolEllipsis)/sizeof(UIColorPanelSymbolEllipsis[0])},
    {"wheel",UIColorPanelSymbolWheel,sizeof(UIColorPanelSymbolWheel)/sizeof(UIColorPanelSymbolWheel[0])},
    {"sliders",UIColorPanelSymbolSliders,sizeof(UIColorPanelSymbolSliders)/sizeof(UIColorPanelSymbolSliders[0])},
    {"palette",UIColorPanelSymbolPalette,sizeof(UIColorPanelSymbolPalette)/sizeof(UIColorPanelSymbolPalette[0])},
    {"image",UIColorPanelSymbolImage,sizeof(UIColorPanelSymbolImage)/sizeof(UIColorPanelSymbolImage[0])},
    {"grid",UIColorPanelSymbolGrid,sizeof(UIColorPanelSymbolGrid)/sizeof(UIColorPanelSymbolGrid[0])},
    {"pencils",UIColorPanelSymbolPencils,sizeof(UIColorPanelSymbolPencils)/sizeof(UIColorPanelSymbolPencils[0])},
    {"eyedropper",UIColorPanelSymbolEyedropper,sizeof(UIColorPanelSymbolEyedropper)/sizeof(UIColorPanelSymbolEyedropper[0])}
};
