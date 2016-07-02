//
//  ButtonsView.m
//  FlowMenuAnimation
//
//  Created by Bear on 16/6/23.
//  Copyright © 2016年 Bear. All rights reserved.
//

#import "ButtonsView.h"
#import "SpecialBtn.h"

@interface ButtonsView () <UIDynamicAnimatorDelegate, UICollisionBehaviorDelegate>
{
    NSArray         *_btnArray;
    CAShapeLayer    *_pathLayer;
    UIDynamicAnimator *_animator;
    UIAttachmentBehavior    *_firstBtnDragBehavior;
    
    UITapGestureRecognizer  *_tapGesture;
    UIPanGestureRecognizer  *_panGesture;
}

@end

@implementation ButtonsView



- (instancetype)initWithFrame:(CGRect)frame btnsArray:(NSArray *)btnArray
{
    self = [super initWithFrame:CGRectMake(0, -20, frame.size.width, frame.size.height)];
    
    if (self) {
        
        if (showPathBgViewColor == YES) {
            self.backgroundColor = [[UIColor brownColor] colorWithAlphaComponent:0.4];
        }else{
            self.backgroundColor = [UIColor clearColor];
        }
        
        _btnArray = btnArray;
        _aniamtionDuring = 2.0;
        
        _pathLayer = [CAShapeLayer layer];
        
        if (!_animator) {
            _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self];
            _animator.delegate = self;
        }
        
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gestureEvent:)];
        _tapGesture.numberOfTapsRequired = 1;
        [self addGestureRecognizer:_tapGesture];
        
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureEvent:)];
        [self addGestureRecognizer:_panGesture];
    }
    
    return self;
}


- (void)gestureEvent:(UIGestureRecognizer *)gesture
{
    CGPoint touchPoint = [gesture locationInView:self];
    NSLog(@"tapPoint :%@", NSStringFromCGPoint(touchPoint));
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self initDragBehaviourWithAnchorPosition:touchPoint];
        [_animator addBehavior:_firstBtnDragBehavior];
    }
    else if (gesture.state == UIGestureRecognizerStateChanged) {
        [_firstBtnDragBehavior setAnchorPoint:touchPoint];
    }
    else if (gesture.state == UIGestureRecognizerStateEnded) {
        [_animator removeBehavior:_firstBtnDragBehavior];
    }
}

- (CGFloat)setXX:(CGFloat)xx
{
    CGFloat reffer_width = 896;
    CGFloat returnXX = 1.0 * xx / reffer_width * self.width;
    
    return returnXX;
}


- (void)showBtnsAnimation
{
    [_animator removeAllBehaviors];
    
    if (showPath) {
        _pathLayer.path = _beizerPath.CGPath;
        _pathLayer.fillColor = [UIColor clearColor].CGColor;
        _pathLayer.strokeColor = [UIColor orangeColor].CGColor;
        _pathLayer.lineWidth = 2.0;
        [self.layer addSublayer:_pathLayer];
    }
    
    CGFloat btn_gap = [self setXX:16];
    for (int i = 0; i < [_btnArray count]; i++) {
        
        SpecialBtn *tempBtn = _btnArray[i];
        tempBtn.tag = i;
        [self addSubview:tempBtn];
        
        //  设定初始位置
        [tempBtn setX:(tempBtn.width + btn_gap) * ([_btnArray count] - 1 - i) + btn_gap];
        [tempBtn setY:-tempBtn.height];
        
        //  添加球与球之间的附着行为
        if (i > 0) {
            UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:_btnArray[i] attachedToItem:_btnArray[i - 1]];
            [attachmentBehavior setLength:tempBtn.width + 10];
            [attachmentBehavior setDamping:10.01];
            [attachmentBehavior setFrequency:1];
            [_animator addBehavior:attachmentBehavior];
            
        }
        
        //  重力行为
        UIGravityBehavior *gravityBehavior = [[UIGravityBehavior alloc] init];
        [gravityBehavior addItem:tempBtn];
        
        //  最后一个球处理
        if (i == [_btnArray count] - 1) {
            [self dealLastBtnGravityBehavior:gravityBehavior tempBtn:tempBtn];
            
        }

        //  碰撞行为
        UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] init];
        [collisionBehavior addItem:tempBtn];
        [collisionBehavior addBoundaryWithIdentifier:@"path" forPath:_beizerPath];
        
        //  动力元素行为
        UIDynamicItemBehavior *itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[tempBtn]];
        itemBehavior.resistance = 0.2;
        itemBehavior.allowsRotation = YES;
        itemBehavior.angularResistance = 5.0;
        itemBehavior.friction = 0.8;
        
        
        [_animator addBehavior:gravityBehavior];
        [_animator addBehavior:collisionBehavior];
        [_animator addBehavior:itemBehavior];
    }
    
    [self pushBehavior];
    
}


//  对最后一个球回滚时的立即响应
- (void)dealLastBtnGravityBehavior:(UIGravityBehavior *)gravityBehavior tempBtn:(SpecialBtn *)tempBtn
{
    __block CGPoint positionLast = CGPointMake(0, 0);
    __block BOOL pushLeft = NO;
    
    [gravityBehavior setAction:^{
        
        if (pushLeft == NO) {
            CGPoint positionNow = tempBtn.layer.position;
            
            //  right
            if (positionNow.x - positionLast.x >= 0) {
                nil;
            }
            //  left
            else{
                
                pushLeft = YES;
                
                //  移除原先的附着行为
                for (UIDynamicBehavior *behavior in _animator.behaviors) {
                    if ([behavior isKindOfClass:[UIAttachmentBehavior class]]) {
                        [_animator removeBehavior:behavior];
                    }
                }
                
                //  重新添加球与球之间的附着行为
                for (int i = 0; i < [_btnArray count]; i++) {
                    if (i > 0) {
                        UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:_btnArray[i] attachedToItem:_btnArray[i - 1]];
                        [attachmentBehavior setLength:tempBtn.width + 10];
                        [_animator addBehavior:attachmentBehavior];
                        
                    }
                }
                
                //  最后一个球向左push
                UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[tempBtn] mode:UIPushBehaviorModeContinuous];
                pushBehavior.pushDirection = CGVectorMake(-1, -0.5);
                pushBehavior.magnitude = 2.9;
                [_animator addBehavior:pushBehavior];
            }
            
            positionLast = positionNow;
        }
    }];
}

- (void)pushBehavior
{
    
    UIButton *tempBtn = _btnArray[0];
    
    UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[tempBtn] mode:UIPushBehaviorModeInstantaneous];
    pushBehavior.pushDirection = CGVectorMake(1, 0);
    pushBehavior.magnitude = 0.1;
    
    [_animator addBehavior:pushBehavior];
}

- (void)closeBtnsAniamtion
{

}


- (void)initDragBehaviourWithAnchorPosition:(CGPoint)anchorPosition {
    UIView *ballView = [_btnArray lastObject];
    _firstBtnDragBehavior = [[UIAttachmentBehavior alloc] initWithItem:ballView attachedToAnchor:anchorPosition];
    double length = [self getDistanceBetweenAnchor:anchorPosition andBallView:ballView];
    [_firstBtnDragBehavior setLength:((CGFloat) length  < 20) ? (CGFloat) length : 20];
}

- (double)getDistanceBetweenAnchor:(CGPoint)anchor andBallView:(UIView *)ballView {
    return sqrt(pow((anchor.x - ballView.center.x), 2.0) + pow((anchor.y - ballView.center.y), 2.0));
}

#pragma mark - UIDynamicAnimatorDelegate

- (void)dynamicAnimatorWillResume:(UIDynamicAnimator *)animator
{
    NSLog(@"--dynamicAnimatorWillResume");
}

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator
{
    NSLog(@"--dynamicAnimatorDidPause");
}


@end
