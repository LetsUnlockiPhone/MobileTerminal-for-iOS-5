//
// Preferences.m
// Terminal

#import "Preferences.h"

#import <UIKit/UIKit.h>

#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UIBezierPath-UIInternal.h>
#import <UIKit/UIFieldEditor.h>
#import <UIKit/UIFont.h>
#import <UIKit/UIOldSliderControl.h>
/* XXX: I hate this codebase */
#define UIInterfaceOrientation int
#import <UIKit/UIPickerView.h>
#import <UIKit/UIPickerTableCell.h>
#import <UIKit/UIPreferencesControlTableCell.h>
#import <UIKit/UIPreferencesTextTableCell.h>
#import <UIKit/UIScreen.h>
#import <UIKit/UISimpleTableCell.h>
#import <UIKit/UISwitch.h>
#import <UIKit/UIViewController-UINavigationControllerItem.h>

#import "MobileTerminal.h"
#import "Settings.h"
#import "PTYTextView.h"
#import "Constants.h"
#import "Color.h"
#import "Menu.h"
#import "PieView.h"
#import "Log.h"

#import "ColorWidgets.h"
#import "PreferencesGroup.h"
#import "PreferencesDataSource.h"


@interface MenuTableCell : UIPreferencesTableCell
{
    MenuView *menu;
}

@property(nonatomic, readonly) MenuView *menu;

@end

//______________________________________________________________________________

@implementation MenuTableCell

@synthesize menu;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setShowSelection:NO];
        menu = [[MenuView alloc] init];
        [menu setShowsEmptyButtons:YES];
        [menu loadMenu];
        [menu setOrigin:CGPointMake(70,30)];
        [self addSubview:menu];
    }
    return self;
}

- (void)dealloc
{
    [menu release];
    [super dealloc];
}

- (void)drawBackgroundInRect:(struct CGRect)fp8 withFade:(float)fp24
{
    [super drawBackgroundInRect: fp8 withFade: fp24];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextAddPath(context, [_fillPath _pathRef]);
    CGContextClip(context);
    CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGContextFillRect(context, fp8);
    CGContextRestoreGState(context);
}

#pragma mark UIPreferencesTableCell delegate methods

- (float)getHeight
{
    return [self frame].size.height;
}

@end

//______________________________________________________________________________
//______________________________________________________________________________

@interface MenuPrefsPage : UIViewController
{
    UIPreferencesTable *table;
    PreferencesDataSource *prefSource;

    Menu *menu;
    MenuView *menuView;
    MenuButton *editButton;

    UITextField *titleField;
    TextTableCell *commandFieldCell;
    UIPreferencesControlTableCell *submenuSwitchCell;
    UISwitch *submenuSwitch;

    UIPushButton *openSubmenu;
}

@property(nonatomic, readonly) MenuView *menuView;

- (id)initWithMenu:(Menu *)menu_ title:(NSString *)title;
//- (void)menuButtonPressed:(MenuButton *)button;
- (void)selectButtonAtIndex:(int)index;
- (void)update;

@end

//______________________________________________________________________________

@implementation MenuPrefsPage

@synthesize menuView;

- (id)initWithMenu:(Menu *)menu_ title:(NSString *)title
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        menu = menu_;
        [self setTitle:(title ? title : @"Menu")];
    }
    return self;
}

- (void)loadView
{
    prefSource = [[PreferencesDataSource alloc] init];
    PreferencesGroup *menuGroup = [PreferencesGroup groupWithTitle:nil icon:nil];

    // ---------------------------------------------------- the menu button grid
 
    MenuTableCell *cell = [[MenuTableCell alloc] initWithFrame:CGRectMake(0, 0, 300, 235)];
    menuView = [cell menu];
    if (menu)
        [menuView loadMenu:menu];
    [menuView setDelegate:self];
    [menuGroup addCell:cell];

    // ------------------------------------------------- button title text field
 
    TextTableCell *titleFieldCell = [menuGroup addTextField:@"Title" value:nil];
    [titleFieldCell setTarget:self];
    [titleFieldCell setTextChangedAction:@selector(onTextChanged:)];
    [titleFieldCell setReturnAction:@selector(onTextReturn)];
    titleField = [titleFieldCell textField];
    [titleField setPlaceholder:@"<button label>"];

    // ------------------------------------------------------ command text field
 
    commandFieldCell = [menuGroup addTextField:@"Command" value:nil];
    [commandFieldCell setTarget:self];
    [commandFieldCell setReturnAction:@selector(onCommandReturn)];
    UITextField *commandField = [commandFieldCell textField];
    [commandField setPlaceholder:@"<command to run>"];
    [commandField setReturnKeyType:9];

    // --------------------------------------------------- toggle submenu button
 
    submenuSwitchCell = [menuGroup addSwitch:@"Submenu" target:self action:@selector(submenuSwitched:)];
    [submenuSwitchCell setShowDisclosure:NO];
    [submenuSwitchCell setUsesBlueDisclosureCircle:YES];
    [submenuSwitchCell setDisclosureClickable:YES];
    submenuSwitch = [submenuSwitchCell control];

    [prefSource addGroup:menuGroup];

    // -------------------------------------------------------- the table itself
 
    table = [[UIPreferencesTable alloc]
        initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [table setAllowsRubberBanding:NO];
    [table setDataSource:prefSource];
    [table setDelegate:self];
    [table reloadData];
    [self setView:table];

    // Select the first button in the button grid
    [self selectButtonAtIndex:0];
}

- (void)dealloc
{
    [table setDataSource:nil];
    [table setDelegate:nil];
    [table release];
    [prefSource release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Reset the table by deselecting the current selection
    [table selectRow:-1 byExtendingSelection:NO withFade:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Though this keyboard is not used for input, it still shows up
    [table setKeyboardVisible:NO animated:NO];
}

#pragma mark Other

- (void)selectButtonAtIndex:(int)index
{
    editButton = [[self menuView] buttonAtIndex:index];
    [menuView selectButton:editButton];
    [self update];
}

- (void)update
{
    BOOL isMenu = [editButton isMenuButton];
    BOOL isNavi = [editButton isNavigationButton];

    [titleField setText:[editButton.item title]];
    [commandFieldCell setUserInteractionEnabled:!isMenu];
    [[commandFieldCell textField] setText:[editButton.item commandString]];
    [submenuSwitch setOn:isMenu];
    [submenuSwitchCell setShowDisclosure:isNavi animated:YES];

    // Animate the enabling/disabling of the Submenu switch
    [UIView beginAnimations:@"slideSwitch"];
    if (isNavi) {
        [[submenuSwitchCell disclosureView] addTarget:self action:@selector(openSubmenuAction) forControlEvents:64];
        [submenuSwitch setOrigin:CGPointMake(156.0f, 9.0f)];
    } else {
        [submenuSwitch setOrigin:CGPointMake(206.0f, 9.0f)];
    }
    [UIView endAnimations];

    [table reloadData];
}

# pragma mark MenuView callback methods

- (BOOL)shouldLoadMenuWithButton:(MenuButton *)button
{
    return NO;
}

- (void)menuButtonPressed:(MenuButton *)button
{
    editButton = button;
    [self update];
}

#pragma mark TextTableCell callback methods

- (void)onTextChanged:(NSString *)text
{
    [editButton.item setTitle:text];
}

- (void)onTextReturn
{
    // Manually hide the table's keyboard if command field is disabled
    if ([editButton isMenuButton])
        [table setKeyboardVisible:NO animated:YES];
}

- (void)onCommandReturn
{
    // Manually hide the table's keyboard
    // NOTE: while the table's keyboard is not used for input (UITextField has
    //       its own), it is needed for making the table view auto-scroll
    [table setKeyboardVisible:NO animated:YES];

    NSString *text = [[commandFieldCell textField] text];
    [editButton.item setCommandString:[NSString stringWithString:text]];
    if ([editButton.item title] == nil || [[editButton.item title] length] == 0) {
        [editButton.item setTitle:text];
        [titleField setText:text];
    }

    [self update];
}

#pragma mark Submenu methods

- (void)submenuSwitched:(UISwitch *)control
{
    [editButton.item setSubmenu:([control isOn] ? [Menu menu] : nil)];
    // FIXME: shouldn't this update be in the setSubmenu method?
    [editButton update];
    [self update];
}

- (void)openSubmenuAction
{
    MenuItem *item = editButton.item;
    MenuPrefsPage *newMenuPrefs = [[MenuPrefsPage alloc]
        initWithMenu:[item submenu] title:[item title]];
    [[self navigationController] pushViewController:newMenuPrefs animated:YES];
    [newMenuPrefs release];
}

@end

//______________________________________________________________________________
//______________________________________________________________________________

@interface GestureTableCell : UIPreferencesTableCell
{
    PieView *pieView;
}

@property(nonatomic, readonly) PieView *pieView;

@end

//______________________________________________________________________________

@implementation GestureTableCell

@synthesize pieView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setShowSelection:NO];
        pieView = [[PieView alloc] init];
        [pieView setCenter:CGPointMake(
                160.0f, [self bounds].size.height / 2.0f)];
        [self addSubview:pieView];
    }
    return self;
}

- (void)dealloc
{
    [pieView release];
    [super dealloc];
}

- (void)drawBackgroundInRect:(struct CGRect)fp8 withFade:(float)fp24
{
    [super drawBackgroundInRect: fp8 withFade: fp24];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextAddPath(context, [_fillPath _pathRef]);
    CGContextClip(context);
    CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGContextFillRect(context, fp8);
    CGContextRestoreGState(context);
}

#pragma mark UIPreferencesTableCell delegate methods

- (float)getHeight
{
    return [self frame].size.height;
}

@end

//______________________________________________________________________________
//______________________________________________________________________________

@interface GesturePrefsPage : UIViewController
{
    UIPreferencesTable *table;
    PreferencesDataSource *prefSource;

    PieView *pieView;
    PieButton *editButton;
    UITextField *commandField;

    int swipes;
}

@property(nonatomic, readonly) PieView *pieView;

- (id)initWithSwipes:(int)swipes_;
- (void)pieButtonPressed:(PieButton *)button;

@end

//______________________________________________________________________________

@implementation GesturePrefsPage

@synthesize pieView;

- (id)initWithSwipes:(int)swipes_
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setTitle:@"Gestures"];
        swipes = swipes_;
    }
    return self;
}

- (void)loadView
{
    prefSource = [[PreferencesDataSource alloc] init];
    PreferencesGroup *menuGroup = [PreferencesGroup groupWithTitle:nil icon:nil];

    // --------------------------------------------------------- the gesture pie
 
    GestureTableCell *cell = [[GestureTableCell alloc]
        initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 235.0f)];
    pieView = [cell pieView];
    NSDictionary * sg = [[Settings sharedInstance] swipeGestures];
    for (int i = 0; i < 8; i++) {
        NSString *command = [sg objectForKey:ZONE_KEYS[(i + 8 - 2) % 8 + swipes * 8]];
        if (command != nil)
            [[pieView buttonAtIndex:i] setCommand:command];
    }
    [pieView setDelegate:self];
    [menuGroup addCell:cell];

    // ------------------------------------------------------ command text field
 
    TextTableCell *commandFieldCell = [menuGroup addTextField:@"Command" value:nil];
    [commandFieldCell setTarget:self];
    [commandFieldCell setTextChangedAction:@selector(onCommandChanged:)];
    [commandFieldCell setReturnAction:@selector(onCommandReturn)];
    commandField = [commandFieldCell textField];
    [commandField setPlaceholder:@"<command to run>"];
    [commandField setReturnKeyType:9];
    [prefSource addGroup:menuGroup];

    // ---------------------------------------------------------------- submenus
 
#if 0 // FIXME
    if (swipes == 0) {
        PreferencesGroup *group = [PreferencesGroup groupWithTitle:nil icon:nil];
        [group addPageButton:@"Long Swipes"];
        [group addPageButton:@"Two Finger Swipes"];
        [prefSource addGroup:group];

        group = [PreferencesGroup groupWithTitle:nil icon:nil];
        [group addColorPageButton:@"Gesture Frame Color" colorRef:[[Settings sharedInstance] gestureFrameColorRef]];
        [prefSource addGroup:group];
    }
#endif

    // -------------------------------------------------------- the table itself

    table = [[UIPreferencesTable alloc]
        initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [table setAllowsRubberBanding:NO];
    [table setDataSource:prefSource];
    [table setDelegate:self];
    [table reloadData];
    [self setView:table];

    [pieView selectButton:[pieView buttonAtIndex:2]];
    [self pieButtonPressed:[pieView buttonAtIndex:2]];
}

- (void)dealloc
{
    [table setDataSource:nil];
    [table setDelegate:nil];
    [table release];
    [prefSource release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Reset the table by deselecting the current selection
    [table selectRow:-1 byExtendingSelection:NO withFade:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Though this keyboard is not used for input, it still shows up
    if ([table keyboard])
        [table setKeyboardVisible:NO animated:NO];

    Settings *settings = [Settings sharedInstance];
    for (int i = 0; i < 8; i++) {
        NSString *command = [[pieView buttonAtIndex:i] command];
        NSString *zone = ZONE_KEYS[(i + 8 - 2) % 8 + swipes * 8];
        [settings setCommand:command forGesture:zone];
    }
}

#pragma mark Other

- (void)update
{
    [commandField setText:[editButton commandString]];
    [table reloadData];
}

# pragma mark PieView callback methods

- (void)pieButtonPressed:(PieButton *)button
{
    editButton = button;
    [self update];
}

#pragma mark TextTableCell callback methods

- (void)onCommandChanged:(NSString *)text
{
    [editButton setTitle:text];
}

- (void)onCommandReturn
{
    // Manually hide the table's keyboard
    // NOTE: while the table's keyboard is not used for input (UITextField has
    //       its own), it is needed for making the table view auto-scroll
    [table setKeyboardVisible:NO animated:YES];

    NSString *text = [commandField text];
    [editButton setCommandString:[NSString stringWithString:text]];
    if ([editButton title] == nil || [[editButton title] length] == 0)
        [editButton setTitle:text];

    [self update];
}

@end

//______________________________________________________________________________
//______________________________________________________________________________

@interface FontChooser : UIView
{
    UIPickerView *fontPicker;
    UITable *pickerTable;

    NSMutableArray *fontNames;

    id delegate;

}

@property(nonatomic, assign) id delegate;

- (void)createFontList;
- (void)selectFont:(NSString *)font;
- (int)rowForFont:(NSString *)fontName;

@end

//______________________________________________________________________________

@implementation FontChooser

@synthesize delegate;

- (id)initWithFrame:(struct CGRect)rect
{
    self = [super initWithFrame:rect];
    if (self) {
        [self createFontList];
        fontPicker = [[UIPickerView alloc] initWithFrame:[self bounds]];
        [fontPicker setDelegate:self];
        [self addSubview:fontPicker];
    }

    return self;
}

- (void)dealloc
{
    [fontPicker setDelegate:nil];
    [fontPicker release];
    [fontNames release];

    [super dealloc];
}

#pragma mark Other

- (void)createFontList
{
    fontNames = [[NSMutableArray alloc] init];
    NSArray *familyNames = [UIFont familyNames];
    for (NSArray *name in familyNames)
        [fontNames addObjectsFromArray:[UIFont fontNamesForFamilyName:name]];
    [fontNames sortUsingSelector:@selector(compare:)];
}

- (void)selectFont:(NSString *)fontName
{
    int row = [self rowForFont:fontName];
    [fontPicker selectRow:row inColumn:0 animated:NO];
    [[fontPicker selectedTableCellForColumn:0] setChecked:YES];
}

#pragma mark UIPickerView delegate methods

- (int)numberOfComponentsInPickerView:(UIPickerView *)picker
{
    return 1;
}

- (int)pickerView:(UIPickerView *)picker numberOfRowsInComponent:(int)col
{
    return [fontNames count];
}

- (int)rowForFont:(NSString *)fontName
{
    int count = [fontNames count];
    for (int i = 0; i < count; i++)
        if ([[fontNames objectAtIndex:i] isEqualToString:fontName])
            return i;
    return 0;
}

#pragma mark UIPickerView delegate methods

- (float)pickerView:(UIPickerView *)picker rowHeightForComponent:(int)component
{
    return 40.0f;
}

- (UIPickerTableCell *)pickerView:(UIPickerView *)picker tableCellForRow:(int)row inColumn:(int)col
{
    UIPickerTableCell *cell = [[UIPickerTableCell alloc] init];
    NSString *fontName = [fontNames objectAtIndex:row];
    [cell setTitle:fontName];
    [[cell titleTextLabel] setFont:[UIFont fontWithName:fontName size:22.0f]];
    return cell;
}

- (void)pickerView:(UIPickerView *)picker didSelectRow:(int)row inComponent:(int)component
{
    if ([delegate respondsToSelector:@selector(setFont:)])
        [delegate performSelector:@selector(setFont:)
                       withObject:[fontNames objectAtIndex:row]];
}

@end

//______________________________________________________________________________
//______________________________________________________________________________

@interface FontPage : UIViewController
{
    UIPreferencesTable *table;
    PreferencesDataSource *prefSource;

    FontChooser *fontChooser;
    UIOldSliderControl *sizeSlider;
    UIOldSliderControl *widthSlider;

    @private
        int terminalIndex_;
        TerminalConfig *config_;
}

- (FontChooser *)fontChooser;
- (void)selectFont:(NSString *)font size:(int)size width:(float)width;
- (void)sizeSelected:(UIOldSliderControl *)control;
- (void)widthSelected:(UIOldSliderControl *)control;

- (void)setFont:(NSString *)font;
- (void)setFontSize:(int)size;
- (void)setFontWidth:(float)width;

@end

//______________________________________________________________________________

@implementation FontPage

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setTitle:@"Font"];
        // For convenience, store the index and a pointer to the configuration
        // for the selected terminal
        terminalIndex_ =
            [(PreferencesController *)[self navigationController] terminalIndex];
        config_ = [TerminalConfig configForTerminal:terminalIndex_];
    }
    return self;
}

- (void)loadView
{
    prefSource = [[PreferencesDataSource alloc] init];
    PreferencesGroup *group;

    // -------------------------------------------------- empty space for picker

    group = [PreferencesGroup groupWithTitle:nil icon:nil];
    group.titleHeight = 220;
    [prefSource addGroup:group];

    // ------------------------------------------------------------- font picker

#if 0
    CGSize screenSize = [UIHardware mainScreenSize];
    CGRect chooserRect = CGRectMake(0, 0, screenSize.width, 210);
#else
    CGRect chooserRect = [[UIScreen mainScreen] bounds];
    chooserRect.size.height = 210;
#endif
    fontChooser = [[FontChooser alloc] initWithFrame:chooserRect];
    [fontChooser setDelegate:self];

    // -------------------------------------------------- size and width sliders

    UIPreferencesControlTableCell *cell;
    group = [PreferencesGroup groupWithTitle:nil icon:nil];
    cell = [group addIntValueSlider:@"Size" range:NSMakeRange(7, 13) target:self action:@selector(sizeSelected:)];
    sizeSlider = [cell control];
    cell = [group addFloatValueSlider:@"Width" minValue:0.5f maxValue:1.0f target:self action:@selector(widthSelected:)];
    widthSlider = [cell control];
    [prefSource addGroup:group];

    // -------------------------------------------------------- the table itself

    table = [[UIPreferencesTable alloc]
        initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [table addSubview:fontChooser];
    [table setAllowsRubberBanding:NO];
    [table setDataSource:prefSource];
    [table reloadData];
    [self setView:table];
}

- (void)dealloc
{
    [table setDataSource:nil];
    [table setDelegate:nil];
    [table release];
    [prefSource release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self selectFont:[config_ font]
                size:[config_ fontSize] width:[config_ fontWidth]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    MobileTerminal *app = [MobileTerminal application];
    // FIXME: 'textviews' was removed from main app class
#if 0
    if (terminalIndex_ < [[app textviews] count])
        [[[app textviews] objectAtIndex:terminalIndex_] resetFont];
#endif
}

#pragma mark Other

- (void)selectFont:(NSString *)font size:(int)size width:(float)width
{
    [fontChooser selectFont:font];
    [sizeSlider setValue:(float)size];
    [widthSlider setValue:width];
}

- (void)sizeSelected:(UIOldSliderControl *)control
{
    [control setValue:floor([control value])];
    [self setFontSize:(int)[control value]];
}

- (void)widthSelected:(UIOldSliderControl *)control
{
    [self setFontWidth:[control value]];
}

- (FontChooser *)fontChooser { return fontChooser; };

#pragma mark FontChooser delegate methods

- (void)setFont:(NSString *)font
{
    [config_ setFont:font];
}

#pragma mark Size/width slider methods

- (void)setFontSize:(int)size
{
    [config_ setFontSize:size];
}

- (void)setFontWidth:(float)width
{
    [config_ setFontWidth:width];
}

@end

//______________________________________________________________________________
//______________________________________________________________________________

@interface ColorPage : UIViewController
{
    UIPreferencesTable *table;
    PreferencesDataSource *prefSource;

    ColorTableCell *colorField;
    UIOldSliderControl *redSlider;
    UIOldSliderControl *greenSlider;
    UIOldSliderControl *blueSlider;
    UIOldSliderControl *alphaSlider;

    UIColor *color;
    id delegate;
}

@property(nonatomic, retain) UIColor *color;

- (id)initWithColor:(UIColor *)color_ delegate:(id)delegate_ title:(NSString *)title;
- (void)update;

@end

//______________________________________________________________________________

@implementation ColorPage

@synthesize color;

- (id)initWithColor:(UIColor *)color_ delegate:(id)delegate_ title:(NSString *)title
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setTitle:title];
        color = [color_ retain];
        delegate = delegate_;
    }
    return self;
}

- (void)loadView
{
    prefSource = [[PreferencesDataSource alloc] init];
    PreferencesGroup *group;

    // ------------------------------------------------------------- color field

    group = [PreferencesGroup groupWithTitle:@"Color" icon:nil];
    colorField = [group addColorField];
    [prefSource addGroup:group];

    // ------------------------------------------------------------- rgb sliders

    group = [PreferencesGroup groupWithTitle:@"Values" icon:nil];
    redSlider = [[group addFloatValueSlider:@"Red" minValue:0 maxValue:1 target:self action:@selector(sliderChanged:)] control];
    greenSlider = [[group addFloatValueSlider:@"Green" minValue:0 maxValue:1 target:self action:@selector(sliderChanged:)] control];
    blueSlider = [[group addFloatValueSlider:@"Blue" minValue:0 maxValue:1 target:self action:@selector(sliderChanged:)] control];
    [prefSource addGroup:group];

    // ------------------------------------------------------------ alpha slider

    group = [PreferencesGroup groupWithTitle:nil icon:nil];
    alphaSlider = [[group addFloatValueSlider:@"Alpha" minValue:0 maxValue:1 target:self action:@selector(sliderChanged:)] control];
    [prefSource addGroup:group];

    // -------------------------------------------------------- the table itself

    table = [[UIPreferencesTable alloc]
        initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [table setAllowsRubberBanding:NO];
    [table setDataSource:prefSource];
    [table reloadData];
    [self setView:table];

    // Set the initial values of the color field and sliders
    [self update];
}

- (void)dealloc
{
    [color release];
    [table setDataSource:nil];
    [table setDelegate:nil];
    [table release];
    [prefSource release];

    [super dealloc];
}

- (void)update
{
    [colorField setColor:color];

    const CGFloat *rgba = CGColorGetComponents([color CGColor]);
    [redSlider setValue:rgba[0]];
    [greenSlider setValue:rgba[1]];
    [blueSlider setValue:rgba[2]];
    [alphaSlider setValue:rgba[3]];
}

#pragma mark Slider callbacks

- (void)sliderChanged:(id)slider
{
    UIColor *c = colorWithRGBA([redSlider value], [greenSlider value], [blueSlider value], [alphaSlider value]);
    if (color != c) {
        [color release];
        color = [c retain];

        [colorField setColor:color];

        if ([delegate respondsToSelector:@selector(colorChanged:)])
            [delegate performSelector:@selector(colorChanged:)
                withObject:[NSArray arrayWithColor:color]];
    }
}

#pragma mark Properties

- (void)setColor:(UIColor *)color_
{
    if (color != color_) {
        [color release];
        color = [color_ retain];
        [self update];
    }
}

@end

//______________________________________________________________________________
//______________________________________________________________________________

@interface TerminalPrefsPage : UIViewController
{
    UIPreferencesTable *table;
    PreferencesDataSource *prefSource;

    UIPreferencesTextTableCell *fontButton;
    PreferencesGroup *sizeGroup;
    UISwitch *autosizeSwitch;
    UITextField *argumentField;
    UIOldSliderControl *widthSlider;
    UIPreferencesControlTableCell *widthCell;

    ColorPageButtonCell *color0;
    ColorPageButtonCell *color1;
    ColorPageButtonCell *color2;
    ColorPageButtonCell *color3;
    ColorPageButtonCell *color4;

    TerminalConfig *config;
}

@end

//______________________________________________________________________________

@implementation TerminalPrefsPage

- (id)initWithIndex:(int)index
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setTitle:[NSString stringWithFormat:@"Terminal %d", index + 1]];
        config = [TerminalConfig configForTerminal:index];

    }
    return self;
}

- (void)loadView
{
    prefSource = [[PreferencesDataSource alloc] init];
    PreferencesGroup *group;

    // ------------------------------------------------------------- font button

    group = [PreferencesGroup groupWithTitle:nil icon:nil];
    fontButton = [group addPageButton:@"Font"];
    [prefSource addGroup:group];

    // -------------------------------------------------------------- line width

    sizeGroup = [PreferencesGroup groupWithTitle:@"Line Width" icon:nil];
    autosizeSwitch = [[sizeGroup addSwitch:@"Auto Adjust" target:self action:@selector(autosizeSwitched:)] control];
    [autosizeSwitch setOn:[config autosize]];
    widthCell = [sizeGroup addIntValueSlider:@"Width" range:NSMakeRange(40, 60) target:self action:@selector(widthSelected:)];
    widthSlider = [widthCell control];
    [widthSlider setValue:[config width]];
    if ([config autosize])
        [sizeGroup removeCell:widthCell];
    else
        [sizeGroup addCell:widthCell];
    [prefSource addGroup:sizeGroup];

    // --------------------------------------------------------------- arguments

    group = [PreferencesGroup groupWithTitle:@"Arguments" icon:nil];
    TextTableCell *argumentFieldCell = [group addTextField:nil value:nil];
    [argumentFieldCell setTarget:self];
    [argumentFieldCell setReturnAction:@selector(onArgumentReturn)];
    argumentField = [argumentFieldCell textField];
    [argumentField setPlaceholder:@"<command-line arguments>"];
    [argumentField setText:[config args]];
    [prefSource addGroup:group];

    // ------------------------------------------------------------------ colors

    group = [PreferencesGroup groupWithTitle:@"Colors" icon:nil];
    color0 = [group addColorPageButton:@"Background" colorRef:&config.colors[0]];
    color1 = [group addColorPageButton:@"Normal Text" colorRef:&config.colors[1]];
    color2 = [group addColorPageButton:@"Bold Text" colorRef:&config.colors[2]];
    color3 = [group addColorPageButton:@"Cursor Text" colorRef:&config.colors[3]];
    color4 = [group addColorPageButton:@"Cursor Background" colorRef:&config.colors[4]];
    [prefSource addGroup:group];

    // -------------------------------------------------------- the table itself

    table = [[UIPreferencesTable alloc]
        initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [table setDataSource:prefSource];
    [table setDelegate:self];
    [table reloadData];
    [table enableRowDeletion:YES animated:YES];
    [self setView:table];
}

- (void)dealloc
{
    [table setDataSource:nil];
    [table setDelegate:nil];
    [table release];
    [prefSource release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Reset the table by deselecting the current selection
    [table selectRow:-1 byExtendingSelection:NO withFade:animated];
    [fontButton setValue:[config fontDescription]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Though this keyboard is not used for input, it still shows up
    [table setKeyboardVisible:NO animated:NO];
}

#pragma mark Size callback methods

- (void)autosizeSwitched:(UISwitch *)control
{
    BOOL autosize = [control isOn];
    [config setAutosize:autosize];
    if (autosize)
        [sizeGroup removeCell:widthCell];
    else
        [sizeGroup addCell:widthCell];
    [table reloadData];
}

- (void)widthSelected:(UIOldSliderControl *)control
{
    [control setValue:floor([control value])];
    [config setWidth:(int)[control value]];
    [config setWidth:(int)[control value]];
}

#pragma mark TextTableCell callback methods

- (void)onArgumentReturn
{
    [config setArgs:[argumentField text]];

    // Manually hide the table's keyboard
    [table setKeyboardVisible:NO animated:YES];
}

#pragma mark Delegate methods

- (void)tableRowSelected:(NSNotification *)notification
{
    int row = [[notification object] selectedRow];
    UIPreferencesTableCell *cell = [table cellAtRow:row column:0];
    if (cell) {
        UIViewController *vc = nil;

        if (cell == fontButton)
            vc = [[FontPage alloc] init];
        else if ([cell isMemberOfClass:[ColorPageButtonCell class]]) {
            ColorSquare *cs = [(ColorPageButtonCell *)cell colorSquare];
            vc = [[ColorPage alloc] initWithColor:[cs color]
                delegate:cs title:[cell title]];
        }

        if (vc) {
            [[self navigationController] pushViewController:vc animated:YES];
            [vc release];
        }
    }
}

@end

//______________________________________________________________________________
//______________________________________________________________________________

@interface AboutPage : UIViewController
{
    UIPreferencesTable *table;
}
@end

//______________________________________________________________________________

@implementation AboutPage

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setTitle:@"About"];
    }
    return self;
}

- (void)loadView
{
    PreferencesDataSource *prefSource = [[[PreferencesDataSource alloc] init] retain];
    PreferencesGroup *group;

    group = [PreferencesGroup groupWithTitle:@"MobileTerminal" icon:nil];
    [group addValueField:@"Version" value:[NSString stringWithFormat:@"1.0 (%@)", SVN_VERSION]];
    [prefSource addGroup:group];

    group = [PreferencesGroup groupWithTitle:@"Homepage" icon:nil];
    [group addPageButton:@"code.google.com/p/mobileterminal"];
    [prefSource addGroup:group];

    group = [PreferencesGroup groupWithTitle:@"Contributors" icon:nil];
    [group addValueField:nil value:@"allen.porter"];
    [group addValueField:nil value:@"craigcbrunner"];
    [group addValueField:nil value:@"vaumnou"];
    [group addValueField:nil value:@"andrebragareis"];
    [group addValueField:nil value:@"aaron.krill"];
    [group addValueField:nil value:@"kai.cherry"];
    [group addValueField:nil value:@"elliot.kroo"];
    [group addValueField:nil value:@"validus"];
    [group addValueField:nil value:@"DylanRoss"];
    [group addValueField:nil value:@"lednerk"];
    [group addValueField:nil value:@"tsangk"];
    [group addValueField:nil value:@"joseph.jameson"];
    [group addValueField:nil value:@"gabe.schine"];
    [group addValueField:nil value:@"syngrease"];
    [group addValueField:nil value:@"maball"];
    [group addValueField:nil value:@"lennart"];
    [group addValueField:nil value:@"monsterkodi"];
    [group addValueField:nil value:@"saurik"];
    [group addValueField:nil value:@"ashikase"];
    [prefSource addGroup:group];

    table = [[UIPreferencesTable alloc]
        initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [table setDataSource:prefSource];
    [table setDelegate:self];
    [table reloadData];
    [self setView:table];
    [table release];
}

- (void)dealloc
{
    [table setDataSource:nil];
    [table setDelegate:nil];
    [table release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Reset the table by deselecting the current selection
    [table selectRow:-1 byExtendingSelection:NO withFade:animated];
}

#pragma mark Delegate methods

- (void)tableRowSelected:(NSNotification *)notification
{
    if ( [[self view] selectedRow] == 3 )
        [[MobileTerminal application] openURL:
                         [NSURL URLWithString:@"http://code.google.com/p/mobileterminal/"]];
}

@end

//______________________________________________________________________________
//______________________________________________________________________________

@interface PreferencesPage : UIViewController
{
    UIPreferencesTable *table;

    PreferencesGroup *terminalGroup;

    int terminalIndex;
    UIPreferencesTextTableCell *terminalButton[MAX_TERMINALS];
}

@end

//______________________________________________________________________________

@implementation PreferencesPage

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self setTitle:@"Preferences"];
        [[self navigationItem] setLeftBarButtonItem:
             [[UIBarButtonItem alloc] initWithTitle:@"Done" style:5
                target:[MobileTerminal application]
                action:@selector(togglePreferences)]];
    }
    return self;
}

- (void)loadView
{
    PreferencesDataSource *prefSource = [[PreferencesDataSource alloc] init];
    PreferencesGroup *group;

    // --------------------------------------------------------- menu & gestures

    group = [PreferencesGroup groupWithTitle:@"Menu & Gestures" icon:nil];
    [group addPageButton:@"Menu"];
    [group addPageButton:@"Gestures"];
    [prefSource addGroup:group];

    // --------------------------------------------------------------- terminals

    terminalGroup = [PreferencesGroup groupWithTitle:@"Terminals" icon:nil];

    for (int i = 0; i < MAX_TERMINALS; i++)
        terminalButton[i] = [terminalGroup addPageButton:
            [NSString stringWithFormat:@"Terminal %d", i + 1]];

    [prefSource addGroup:terminalGroup];

    // ------------------------------------------------------------------- about

    group = [PreferencesGroup groupWithTitle:@"Other" icon:nil];
    [group addPageButton:@"About"];
    [prefSource addGroup:group];

    // -------------------------------------------------------- the table itself

    table = [[UIPreferencesTable alloc]
        initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    [table setDataSource:prefSource];
    [table setDelegate:self];
    [table reloadData];
    [table enableRowDeletion:YES animated:YES];
    [self setView:table];
}

- (void)dealloc
{
    [table setDataSource:nil];
    [table setDelegate:nil];
    [table release];

    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Reset the table by deselecting the current selection
    [table selectRow:-1 byExtendingSelection:NO withFade:animated];
}

#pragma mark Delegate methods

- (void)tableRowSelected:(NSNotification *)notification
{
    int row = [[notification object] selectedRow];
    UIPreferencesTableCell *cell = [table cellAtRow:row column:0];
    if (cell) {
        NSString *title = [cell title];
        UIViewController *vc = nil;

        if ([title isEqualToString:@"Menu"])
            vc = [[MenuPrefsPage alloc] initWithMenu:nil title:nil];
        else if ([title isEqualToString:@"Gestures"])
            vc = [[GesturePrefsPage alloc] initWithSwipes:0];
#if 0
        else if ([title isEqualToString:@"Long Swipes"])
            vc = [[GesturePrefsPage alloc]initWithSwipes:1];
        else if ([title isEqualToString:@"Two Finger Swipes"])
            vc = [[GesturePrefsPage alloc]initWithSwipes:2];
#endif
        else if ([title isEqualToString:@"About"])
            vc = [[AboutPage alloc] init];
        else {
            // Must be a Terminal cell
            terminalIndex = [[title substringFromIndex:9] intValue] - 1;
            vc = [[TerminalPrefsPage alloc] initWithIndex:terminalIndex];
        }

        if (vc) {
            [[self navigationController] pushViewController:vc animated:YES];
            [vc release];
        }
    }
}

@end

//______________________________________________________________________________
//______________________________________________________________________________

@implementation PreferencesController

// FIXME: This is not updated properly
@synthesize terminalIndex;

- (id)init
{
    self = [super init];
    if (self) {
        [[self navigationBar] setBarStyle:1];
        [self pushViewController:
            [[[PreferencesPage alloc] init] autorelease] animated:NO];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Save the settings to disk
    [[Settings sharedInstance] writeUserDefaults];
}

#pragma mark UINavigationBar delegate methods

- (void)navigationBar:(id)bar buttonClicked:(int)button
{
    switch (button) {
        case 1: // Done
            [[MobileTerminal application] togglePreferences];
            break;
    }
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
