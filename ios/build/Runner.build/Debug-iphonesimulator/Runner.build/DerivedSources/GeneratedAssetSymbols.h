#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "AppIcon" asset catalog image resource.
static NSString * const ACImageNameAppIcon AC_SWIFT_PRIVATE = @"AppIcon";

/// The "LaunchImage" asset catalog image resource.
static NSString * const ACImageNameLaunchImage AC_SWIFT_PRIVATE = @"LaunchImage";

/// The "logo" asset catalog image resource.
static NSString * const ACImageNameLogo AC_SWIFT_PRIVATE = @"logo";

#undef AC_SWIFT_PRIVATE
