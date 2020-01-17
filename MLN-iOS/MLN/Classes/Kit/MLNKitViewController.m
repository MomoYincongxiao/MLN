//
//  MLNKitViewController.h.m
//  MLN
//
//  Created by MoMo on 2019/8/5.
//

#import "MLNKitViewController.h"
#import "MLNKitInstance.h"
#import "MLNLuaBundle.h"
#import "MLNKitInstanceFactory.h"
#import "MLNDataBinding.h"
#import "MLNLuaCore.h"

@interface MLNKitViewController ()

@property (nonatomic, strong) MLNDataBinding *dataBinding;

@end

@implementation MLNKitViewController

- (instancetype)initWithEntryFilePath:(NSString *)entryFilePath
{
    return [self initWithEntryFilePath:entryFilePath extraInfo:nil regClasses:nil];
}

- (instancetype)initWithEntryFilePath:(NSString *)entryFilePath extraInfo:(NSDictionary *)extraInfo
{
    return [self initWithEntryFilePath:entryFilePath extraInfo:extraInfo regClasses:nil];
}

- (instancetype)initWithEntryFilePath:(NSString *)entryFilePath extraInfo:(nullable NSDictionary *)extraInfo regClasses:(nullable NSArray<Class<MLNExportProtocol>> *)regClasses
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        _entryFilePath = entryFilePath;
        _extraInfo = extraInfo.copy;
        _regClasses = regClasses.copy;
    }
    return self;
}

- (BOOL)regClasses:(NSArray<Class<MLNExportProtocol>> *)registerClasses
{
    return [self.kitInstance registerClasses:registerClasses error:NULL];
}

- (void)reload
{
    [self.kitInstance reloadWithEntryFile:_entryFilePath windowExtra:_extraInfo error:NULL];
}

- (void)reloadWithEntryFilePath:(NSString *)entryFilePath
{
    _entryFilePath = entryFilePath;
    [self.kitInstance reloadWithEntryFile:entryFilePath windowExtra:_extraInfo error:NULL];
}

- (void)reloadWithEntryFilePath:(NSString *)entryFilePath bundlePath:(NSString *)bundlePath
{
    [self.kitInstance changeLuaBundleWithPath:bundlePath];
    _entryFilePath = entryFilePath;
    [self.kitInstance reloadWithEntryFile:entryFilePath windowExtra:_extraInfo error:NULL];
}

- (void)reloadWithEntryFilePath:(NSString *)entryFilePath extraInfo:(NSDictionary *)extraInfo bundlePath:(NSString *)bundlePath
{
    [self.kitInstance changeLuaBundleWithPath:bundlePath];
    _entryFilePath = entryFilePath;
    _extraInfo = extraInfo.copy;
    [self.kitInstance reloadWithEntryFile:entryFilePath windowExtra:_extraInfo error:NULL];
}

- (void)changeCurrentBundlePath:(NSString *)bundlePath
{
    [self.kitInstance changeLuaBundleWithPath:bundlePath];
}

- (void)changeCurrentBundle:(MLNLuaBundle *)bundle
{
    [self.kitInstance changeLuaBundle:bundle];
}

- (NSString *)currentBundlePath
{
    return self.kitInstance.currentBundle.bundlePath;
}

- (MLNKitInstanceHandlersManager *)handlerManager
{
    return self.kitInstance.instanceHandlersManager;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    if ([self.delegate respondsToSelector:@selector(kitViewDidLoad:)]) {
        [self.delegate kitViewDidLoad:self];
    }
    [self.kitInstance changeRootView:self.view];
    NSError *error = nil;
    BOOL ret = [self.kitInstance runWithEntryFile:self.entryFilePath windowExtra:self.extraInfo error:&error];
    if (ret) {
        if ([self.delegate respondsToSelector:@selector(kitViewController:didFinishRun:)]) {
            [self.delegate kitViewController:self didFinishRun:self.entryFilePath];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(kitViewController:didFailRun:error:)]) {
            [self.delegate kitViewController:self didFailRun:self.entryFilePath error:error];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([self.delegate respondsToSelector:@selector(kitViewController:viewWillAppear:)]) {
        [self.delegate kitViewController:self viewWillAppear:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self.delegate respondsToSelector:@selector(kitViewController:viewDidAppear:)]) {
        [self.delegate kitViewController:self viewDidAppear:animated];
    }
    [self.kitInstance doLuaWindowDidAppear];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([self.delegate respondsToSelector:@selector(kitViewController:viewWillDisappear:)]) {
        [self.delegate kitViewController:self viewWillDisappear:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self.delegate respondsToSelector:@selector(kitViewController:viewDidDisappear:)]) {
        [self.delegate kitViewController:self viewDidDisappear:animated];
    }
    [self.kitInstance doLuaWindowDidDisappear];
}

- (MLNKitInstance *)kitInstance
{
    if (!_kitInstance) {
        _kitInstance = [[MLNKitInstanceFactory defaultFactory] createKitInstanceWithViewController:self];
        if (_regClasses && _regClasses.count > 0) {
            [_kitInstance registerClasses:_regClasses error:NULL];
        }
    }
    return _kitInstance;
}

@end

@implementation MLNKitViewController (DataBinding)

- (UIView *)findViewById:(NSString *)identifier
{
    lua_State *L = self.kitInstance.luaCore.state;
    int base = lua_gettop(L);
    lua_getglobal(L, "layout");
    if (!lua_istable(L, -1)) {
        lua_settop(L, base);
        return nil;
    }
    lua_pushstring(L, identifier.UTF8String);
    lua_rawget(L, -2);
    if (!lua_isuserdata(L, -1)) {
          lua_settop(L, base);
          return nil;
      }
    MLNUserData *ud = (MLNUserData *)lua_touserdata(L, -1);
    UIView *view = nil;
    if (ud) {\
        view = (__bridge __unsafe_unretained UIView *)ud->object;
    }
    lua_settop(L, base);
    return view;
}

- (void)bindData:(NSObject *)data key:(NSString *)key
{
    [self.dataBinding bindData:data key:key];
}

- (void)updateDataForKeyPath:(NSString *)keyPath value:(id)value
{
    [self.dataBinding updateDataForKeyPath:keyPath value:value];
}

- (id __nullable)dataForKeyPath:(NSString *)keyPath
{
    return [self.dataBinding dataForKeyPath:keyPath];
}

- (void)addDataObserver:(NSObject<MLNKVObserverProtocol> *)observer forKeyPath:(NSString *)keyPath
{
    [self.dataBinding addDataObserver:observer forKeyPath:keyPath];
}

- (MLNDataBinding *)dataBinding
{
    if (!_dataBinding) {
        _dataBinding = [[MLNDataBinding alloc] init];
    }
    return _dataBinding;
}

@end
