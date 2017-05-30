//
//  ViewController.m
//  CharAnimationDemo
//
//  Created by littlewish on 2017/5/27.
//  Copyright © 2017年 littlewish. All rights reserved.
//

#import "ViewController.h"
#import <CoreText/CoreText.h>

@interface ViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *sourceTextField;

@property (strong, nonatomic) UIView *showLabel;

@property (weak, nonatomic) IBOutlet UIButton *startAnimationBtn;


@property (nonatomic,strong) NSMutableArray *shapeLayers;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.sourceTextField.delegate = self;
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)animation:(id)sender {
    [self.shapeLayers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[CALayer class]]) {
            [self addAnimation:obj index:idx];
        }
    }];
    
}

- (void)addAnimation:(CALayer *)layer index:(NSInteger)index{
    CGFloat f = 0.1;
    CGFloat t = 1;
    if (index % 2 == 0) {
        f = 1;
        t = 0.1;
    }
    // 创建一个基础动画
    CABasicAnimation *animation = [CABasicAnimation new];
    // 设置动画要改变的属性
    animation.keyPath = @"transform.scale";
    animation.fromValue = @(f);
    // 动画的最终属性的值（转7.5圈）
    animation.toValue = @(t);
    // 动画的播放时间
    animation.duration = 1;
    
    animation.repeatCount = 100;
    
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    // 解决动画结束后回到原始状态的问题
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    // 将动画添加到视图bgImgV的layer上
    [layer addAnimation:animation forKey:@"rotation"];
}


- (IBAction)show:(id)sender {
    NSArray *chars = [self characterOfString:self.sourceTextField.text];
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:chars.count];
    if (chars.count > 0) {
        [chars enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSString class]]) {
                UIBezierPath *path = [self transformToBezierPath:obj];
                if (path) {
                    [paths addObject:path];
                }
                
            }
        }];
    }
    
    
    self.shapeLayers = [NSMutableArray arrayWithCapacity:paths.count];
    NSArray *wSizes = [self sizeOfWord:chars];
    
    if (paths.count) {
        __block int i = 0;
        [paths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UIBezierPath class]]) {
                UIBezierPath *p = (UIBezierPath *)obj;
                CAShapeLayer *shapeLayer = [CAShapeLayer layer];
                shapeLayer.strokeColor = [UIColor clearColor].CGColor;
                shapeLayer.fillColor = [UIColor redColor].CGColor;
                shapeLayer.lineWidth = 0.5;
                shapeLayer.lineJoin = kCALineJoinRound;
                shapeLayer.lineCap = kCALineCapRound;
                shapeLayer.path = p.CGPath;
                CGRect rect = shapeLayer.frame;
                rect.origin.x = [self layer_Origin_x:wSizes index:i];
                shapeLayer.frame = rect;
                CATransform3D transform = CATransform3DMakeRotation(M_PI, 1, 0, 0);
                shapeLayer.transform = transform;
                i++;
                [self.shapeLayers addObject:shapeLayer];
            }
        }];
    }
    if (self.showLabel) {
        [self.showLabel removeFromSuperview];
        self.showLabel = nil;
    }
    self.showLabel = [[UIView alloc] initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, 40)];
    self.showLabel.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.showLabel];
    [self.shapeLayers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[CALayer class]]) {
            [self.showLabel.layer addSublayer:obj ];
        }
    }];
    
    
}

- (NSArray *)characterOfString:(NSString *)str{
    NSInteger length = str.length;
    if (length == 0) {
        return @[];
    }
    
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:length];
    for (NSInteger i = 0; i<length; i++) {
        NSRange range = NSMakeRange(i, 1);
        NSString *c = [str substringWithRange:range];
        
        [temp addObject:c];
    }
    
    return [temp copy];
}

- (NSArray *)sizeOfWord:(NSArray *)characters{
    if (characters.count == 0) {
        return @[];
    }
    
    NSMutableArray *sizes = [NSMutableArray arrayWithCapacity:characters.count];
    
    [characters enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSString *str = (NSString *)obj;
            CGSize s = [str sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]}];
            [sizes addObject:@(s.width)];
        }
    }];
    
    return [sizes copy];
}

- (CGFloat)layer_Origin_x:(NSArray *)sizes index:(NSInteger)index{
    CGFloat x = 0.0;
    for (int i = 0; i<index; i++) {
        x += [sizes[i] floatValue];
    }
    
    return x;
}

- (UIBezierPath *)transformToBezierPath:(NSString *)string
{
    UIFont *font = [UIFont systemFontOfSize:14];
    //可变路径
    CGMutablePathRef paths = CGPathCreateMutable();
    
    CFStringRef fontName = (__bridge CFStringRef)font.fontName;
    CGFloat fontSize = font.pointSize;
    //字体声明
    CTFontRef fontRef = CTFontCreateWithName(fontName, fontSize, NULL);
    
    //转换为可变字符串
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:string attributes:@{(__bridge NSString *)kCTFontAttributeName: (__bridge UIFont *)fontRef}];
    
    //行结构
    CTLineRef lineRef = CTLineCreateWithAttributedString((CFAttributedStringRef)attrString);
    //返回块的数组CTRun
    CFArrayRef runArrRef = CTLineGetGlyphRuns(lineRef);
    
    for (int runIndex = 0; runIndex < CFArrayGetCount(runArrRef); runIndex++) {
        const  void *run = CFArrayGetValueAtIndex(runArrRef, runIndex);
        //获取一个块结构CTRun
        CTRunRef runb = (CTRunRef)run;
        
        const  void *CTFontName = kCTFontAttributeName;
        
        const void *runFontC = CFDictionaryGetValue(CTRunGetAttributes(runb), CTFontName);
        //获取字体
        CTFontRef runFontS = (CTFontRef)runFontC;
        
        
        //遍历CTRun内的字形
        for (int i = 0; i < CTRunGetGlyphCount(runb); i++) {
            CFRange range = CFRangeMake(i, 1);
            CGGlyph glyph = 0;
            CTRunGetGlyphs(runb, range, &glyph);
            CGPathRef path = CTFontCreatePathForGlyph(runFontS, glyph, nil);
            CGAffineTransform transform = CGAffineTransformMakeScale(1, 1);
            CGPathAddPath(paths, &transform, path);
            
            CGPathRelease(path);
        }
        CFRelease(runb);
        CFRelease(runFontS);
    }
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointZero];
    [bezierPath appendPath:[UIBezierPath bezierPathWithCGPath:paths]];
    
    CGPathRelease(paths);
    CFRelease(fontName);
    CFRelease(fontRef);
    //CFRelease(lineRef);
    //(runArrRef);
    
    return bezierPath;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    
    return YES;
}

@end
