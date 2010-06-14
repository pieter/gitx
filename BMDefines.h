//
//  BMDefines.h
//  BMScriptTest
//
//  Created by Andre Berg on 27.09.09.
//  Copyright 2009 Berg Media. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

/*!
 * @file BMDefines.h
 * 
 * Provides defines mostly for debugging.
 * ￼￼This file may be included by any project as it does not really contain project-specific symbols. 
 * Consists mainly of stuff I have gathered from multiple sources or defined in my own work to help 
 * ease debugging and/or cross-platform development.
 */

#import <Foundation/Foundation.h>
#import <objc/objc.h>
#import <objc/objc-runtime.h>
#include <TargetConditionals.h>

/// @cond HIDDEN
#ifdef __cplusplus
extern "C" {
#endif

#ifndef _BM_DEFINES_H_
#define _BM_DEFINES_H_ 1
/// @endcond 


/*!
 * @addtogroup project_defines Project Defines
 * @{
 */

// Determine runtine environment 
#if !defined(__MACOSX_RUNTIME__) && !defined(__GNUSTEP_RUNTIME__)
    #if defined(__APPLE__) && defined(__MACH__) && !defined(GNUSTEP)
        /*! 
         * @def MACOSX_RUNTIME
         * Determine runtime environment.
         * Defined if running on Mac OS X. GNUStep will not have this defined.
         */
        #define __MACOSX_RUNTIME__
    #endif // If not Mac OS X, GNUstep?
    #if defined(GNUSTEP) && !defined(__MACOSX_RUNTIME__)
        /*!
         * @def ￼__GNUSTEP_RUNTIME__
         * Determine runtime environment.
         * Defined if running GNUStep. Mac OS X will not have this defined.
         */
        #define __GNUSTEP_RUNTIME__
    #endif // Not Mac OS X or GNUstep, that's a problem.
#endif // !defined(__MACOSX_RUNTIME__) && !defined(__GNUSTEP_RUNTIME__)
    
// If the above did not set the run time environment, error out.
#if !defined(__MACOSX_RUNTIME__) && !defined(__GNUSTEP_RUNTIME__)
    #error Unable to determine run time environment, automatic Mac OS X and GNUstep detection failed
#endif

/*!
 * @def ENABLE_MACOSX_GARBAGE_COLLECTION
 * Preprocessor definition to enable Mac OS X 10.5 (Leopard) Garbage Collection.
 * This preprocessor define enables support for Garbage Collection on Mac OS X 10.5 (Leopard).
 * 
 * Traditional retain / release functionality remains allowing the framework to be used in either 
 * Garbage Collected enabled applications or reference counting applications. 
 * 
 * The framework dynamically picks which mode to use at run-time base on whether or not the 
 * Garbage Collection system is active.
 * 
 * @sa <a href="http://developer.apple.com/documentation/Cocoa/Conceptual/GarbageCollection/index.html" class="external">Garbage Collection Programming Guide</a>
 * @sa <a href="http://developer.apple.com/documentation/Cocoa/Reference/NSGarbageCollector_class/index.html" class="external">NSGarbageCollector Class Reference</a>
 */
#if defined(__MACOSX_RUNTIME__) && defined(MAC_OS_X_VERSION_10_5) && defined(__OBJC_GC__)
    #define ENABLE_MACOSX_GARBAGE_COLLECTION
    #define BM_STRONG_REF                     __strong
    #define BM_WEAK_REF                       __weak
#else
    #define BM_STRONG_REF
    #define BM_WEAK_REF
#endif
    
#if defined(ENABLE_MACOSX_GARBAGE_COLLECTION) && !defined(MAC_OS_X_VERSION_10_5)
#error The Mac OS X Garbage Collection feature requires at least Mac OS X 10.5
#endif

    
/*! 
 * A note to Clang's static analyzer. 
 * It tells about the returning onwnership intentions of methods. 
 * The header documentation of Apple follows:
 * "Marks methods and functions which return an object that needs to be released by the caller but whose names are not consistent with Cocoa naming rules. The recommended fix to this is the rename the methods or functions, but this macro can be used to let the clang static analyzer know of any exceptions that cannot be fixed."
 *
 */
#ifndef NS_RETURNS_RETAINED
    #if defined(__clang__)
        #define NS_RETURNS_RETAINED __attribute__((ns_returns_retained))
    #else
        #define NS_RETURNS_RETAINED
    #endif
#endif
    
    
// To simplify support for 64bit (and Leopard in general), 
// provide the type defines for non Leopard SDKs
#if !(MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5)
    
    // NSInteger/NSUInteger and Max/Mins
    #ifndef NSINTEGER_DEFINED
        #if __LP64__ || NS_BUILD_32_LIKE_64
            typedef long NSInteger;
            typedef unsigned long NSUInteger;
        #else
            typedef int NSInteger;
            typedef unsigned int NSUInteger;
        #endif
        #define NSIntegerMax    LONG_MAX
        #define NSIntegerMin    LONG_MIN
        #define NSUIntegerMax   ULONG_MAX
        #define NSINTEGER_DEFINED 1
    #endif  // NSINTEGER_DEFINED
        
        // CGFloat
    #ifndef CGFLOAT_DEFINED
        #if defined(__LP64__) && __LP64__
            // This really is an untested path (64bit on Tiger?)
            typedef double CGFloat;
            #define CGFLOAT_MIN DBL_MIN
            #define CGFLOAT_MAX DBL_MAX
            #define CGFLOAT_IS_DOUBLE 1
        #else /* !defined(__LP64__) || !__LP64__ */
            typedef float CGFloat;
            #define CGFLOAT_MIN FLT_MIN
            #define CGFLOAT_MAX FLT_MAX
            #define CGFLOAT_IS_DOUBLE 0
        #endif /* !defined(__LP64__) || !__LP64__ */
        #define CGFLOAT_DEFINED 1
    #endif // CGFLOAT_DEFINED
        
    // NS_INLINE
    #if !defined(NS_INLINE)
        #if defined(__GNUC__)
            #define NS_INLINE static __inline__ __attribute__((always_inline))
        #elif defined(__MWERKS__) || defined(__cplusplus)
            #define NS_INLINE static inline
        #elif defined(_MSC_VER)
            #define NS_INLINE static __inline
        #elif defined(__WIN32__)
            #define NS_INLINE static __inline__
        #endif
    #endif
    
#endif  // MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5

/*!
 * @def ￼BM_C99(keyword)
 * C99 conformance defines.
 * Make it possible to safely use keywords and features of the C99 standard.
 * @param keyword a C99 keyword (e.g. restrict)
 */
#if __STDC_VERSION__ >= 199901L
    #define BM_C99(keyword) keyword
#else
    #define BM_C99(keyword) 
#endif
    
/*!
 * @def ￼BM_REQUIRES_NIL_TERMINATION
 * Used to mark variadic methods and functions as requiring nil termination.
 * Nil termination means the last argument of their variable argument list must be nil.
 */
#if !defined(BM_REQUIRES_NIL_TERMINATION)
    #if TARGET_OS_WIN32
        #define BM_REQUIRES_NIL_TERMINATION
    #else
        #if defined(__APPLE_CC__) && (__APPLE_CC__ >= 5549)
            #define BM_REQUIRES_NIL_TERMINATION __attribute__((sentinel(0,1)))
        #else
            #define BM_REQUIRES_NIL_TERMINATION __attribute__((sentinel))
        #endif
    #endif
#endif

/*!
 * @def ￼BM_EXTERN
 * Defines for the extern keyword.
 * Makes it possible to use extern in the proper sense in C++ context included.
 */
/*!
 * @def ￼BM_PRIVATE_EXTERN
 * Defines for the __private_extern__ Apple compiler directive.
 * Makes a symbol public in the binrary (e.g. a library), but hidden outside of it. 
 */
#ifdef __cplusplus
    #define BM_EXTERN           extern "C"
    #define BM_PRIVATE_EXTERN   __private_extern__
#else
    #define BM_EXTERN           extern
    #define BM_PRIVATE_EXTERN   __private_extern__
#endif
    
/*!
 * @def BM_ATTRIBUTES
 * Macro wrapper around GCC <a href="http://gcc.gnu.org/onlinedocs/gcc-4.0.4/gcc/Attribute-Syntax.html#Attribute-Syntax" class="external">__attribute__</a> syntax.
 * @note When a compiler other than GCC 4+ is used, #BM_ATTRIBUTES evaluates to an empty string, removing itself and its arguments from the code to be compiled.</p>
 */
/*!
 * @def BM_EXPECTED
 * Macro wrapper around GCC <a href="http://gcc.gnu.org/onlinedocs/gcc-4.0.4/gcc/Other-Builtins.html#index-g_t_005f_005fbuiltin_005fexpect-2284" class="external">__builtin_expect</a> syntax.
 * 
 * From GCC docs: "You may use __builtin_expect to provide the compiler with branch prediction information. In general, you should prefer to use actual profile feedback for this (-fprofile-arcs), as programmers are notoriously bad at predicting how their programs actually perform. However, there are applications in which this data is hard to collect.
 * 
 * The return value is the value of exp, which should be an integral expression. The value of c must be a compile-time constant. The semantics of the built-in are that it is expected that exp == c."
 * 
 * And from <a href="http://regexkit.sourceforge.net" class="external">RegexKit Framework</a> docs (the origin of this macro):
 *
 * <div class="box important"><div class="table"><div class="row"><div class="label cell">Important:</div><div class="message cell"><span class="code">BM_EXPECTED</span> should only be used when the likelihood of the prediction is nearly certain. <b><i>DO NOT GUESS</i></b>.</div></div></div></div>
 * 
 * BM_EXPECTED [...] is used to provide the compiler with branch prediction information for conditional statements.
 * 
 * An example of an appropriate use is parameter validation checks at the start of a function, such as <span class="code nobr">(aPtr == NULL)</span>. Since callers are always expected to pass a valid pointer, the likelihood of the conditional evaluating to true is extremely unlikely. This allows the compiler to schedule instructions to minimize branch miss-prediction penalties. For example:
 <div class="sourcecode">if(BM_EXPECTED((aPtr == NULL), 0)) { abort(); }</div>
 *
 * @note If a compiler other than GCC 4+ is used then the macro leaves the conditional expression unaltered.
 */
#if defined (__GNUC__) && (__GNUC__ >= 4)
    #define BM_STATIC_INLINE static __inline__ __attribute__((always_inline))
    #define BM_STATIC_PURE_INLINE static __inline__ __attribute__((always_inline, pure))
    #define BM_EXPECTED(cond, expect) __builtin_expect(cond, expect)
    #define BM_ALIGNED(boundary) __attribute__ ((aligned(boundary)))
    #define BM_ATTRIBUTES(attr, ...) __attribute__((attr, ##__VA_ARGS__))
#else
    #define BM_STATIC_INLINE static __inline__
    #define BM_STATIC_PURE_INLINE static __inline__
    #define BM_EXPECTED(cond, expect) cond
    #define BM_ALIGNED(boundary)
    #define BM_ATTRIBUTES(attr, ...)
#endif
    

/*!
 * @def BM_DEBUG_RETAIN_INIT
 * ￼Defines a macro which supplies replacement methods for -[retain] and -[release].
 * This macro is normally used in a global context (e.g. outside main) and followed by BM_DEBUG_RETAIN_SWIZZLE(className) in a local context, which then actually registers the replacement for the Class 'className' with the runtime.
 * @attention This is only intended for <b>debugging purposes</b>. Has no effect if Garbage Collection is enabled.
 */
#define BM_DEBUG_RETAIN_INIT \
    IMP oldRetain;\
    IMP oldRelease;\
    id newRetain(id self, SEL _cmd) {\
        NSUInteger rc = [self retainCount];\
        NSLog(@"%s[0x%x]: retain, rc = %d -> %d",\
        class_getName([self class]), self, rc, rc + 1);\
        return (*oldRetain)(self, _cmd);\
    }\
    void newRelease(id self, SEL _cmd) {\
        NSUInteger rc = [self retainCount];\
        NSLog(@"%s[0x%x]: retain, rc = %d -> %d", \
        class_getName([self class]), self, rc, rc - 1);\
        (*oldRetain)(self, _cmd);\
    }

/*!
 * @def BM_DEBUG_RETAIN_SWIZZLE(className)
 * ￼Swizzles (or replaces) the methods defined by #BM_DEBUG_RETAIN_INIT for className.
 * This macro is normally used in a (function) local scope, provided a #BM_DEBUG_RETAIN_INIT declaration at the beginning of the file (in global context). BM_DEBUG_RETAIN_SWIZZLE(className) then actually registers the replacements defined by #BM_DEBUG_RETAIN_INIT for the Class 'className' with the runtime.
 * @attention This is only intended for <b>debugging purposes</b>. Has no effect if Garbage Collection is enabled.
 * @param className the name of the class to replace the methods for (e.g. <span class="sourcecode darkgray">[SomeClass class]</span>).
 */
#define BM_DEBUG_RETAIN_SWIZZLE(className) \
    oldRetain = class_getMethodImplementation((className), @selector(retain));\
    class_replaceMethod((className), @selector(retain), (IMP)&newRetain, "@@:");\
    oldRelease = class_getMethodImplementation((className), @selector(release));\
    class_replaceMethod((className), @selector(release), (IMP)&newRelease, "v@:");

/*!
 * @}
 */
    
#endif // _BM_DEFINES_H_

#ifdef __cplusplus
}  /* extern "C" */
#endif