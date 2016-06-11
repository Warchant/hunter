cmake_minimum_required(VERSION 3.0)
project(Hunter)


# Inludes
list(APPEND CMAKE_MODULE_PATH "@HUNTER_SELF@/cmake/modules")
include(ExternalProject)
include(hunter_user_error)
include(hunter_status_debug)
include(hunter_test_string_not_empty)


# Check preconditions
hunter_test_string_not_empty("@HUNTER_SELF@")
hunter_test_string_not_empty("@HUNTER_EP_NAME@")
hunter_test_string_not_empty("@HUNTER_PACKAGE_URL@")
hunter_test_string_not_empty("@HUNTER_PACKAGE_SHA1@")
hunter_test_string_not_empty("@HUNTER_PACKAGE_DOWNLOAD_DIR@")
hunter_test_string_not_empty("@HUNTER_PACKAGE_SOURCE_DIR@")
hunter_test_string_not_empty("@HUNTER_PACKAGE_INSTALL_PREFIX@")
hunter_test_string_not_empty("@HUNTER_PACKAGE_CONFIGURATION_TYPES@")
hunter_test_string_not_empty("@HUNTER_INSTALL_PREFIX@")


if(NOT "@MSVC@")
    hunter_user_error("MSBuild scheme only supported with Visual Studio")
endif()

# Check MSVC Platform Toolset
string(COMPARE EQUAL "@HUNTER_MSVC_VERSION@" "10" _is_platform_toolset_v100)
string(COMPARE EQUAL "@HUNTER_MSVC_VERSION@" "11" _is_platform_toolset_v110)
string(COMPARE EQUAL "@HUNTER_MSVC_VERSION@" "12" _is_platform_toolset_v120)
string(COMPARE EQUAL "@HUNTER_MSVC_VERSION@" "14" _is_platform_toolset_v140)

if(_is_platform_toolset_v100)
    set(msvc_platform_toolset "v100")
elseif(_is_platform_toolset_v110)
    set(msvc_platform_toolset "v110")
elseif(_is_platform_toolset_v120)
    set(msvc_platform_toolset "v120")
elseif(_is_platform_toolset_v140)
    set(msvc_platform_toolset "v140")
else()
    hunter_user_error("Visual studio version not supported. Supported versions are: Visual studio 2010, 2011, 2012 and 2014.")
    hunter_user_error("If there is a new version please open an issue at https://github.com/ruslo/hunter and mention @Cyberunner23")
endif()


# Check MSVC Architechture
string(COMPARE EQUAL "@HUNTER_MSVC_ARCH@" "x86"   _is_arch_x86)
string(COMPARE EQUAL "@HUNTER_MSVC_ARCH@" "amd64" _is_arch_x64)

if(_is_arch_x86)
    set(msvc_arch "Win32")
elseif(_is_arch_x64)
    set(msvc_arch "x64")
else()
    hunter_user_error("Architechture supplied is not supported.")
endif()


#Check Configuration Types
string(TOUPPER @HUNTER_PACKAGE_CONFIGURATION_TYPES@ configuration_type_upper)
string(COMPARE EQUAL ${configuration_type_upper} "RELEASE" _is_release)
string(COMPARE EQUAL ${configuration_type_upper} "DEBUG"   _is_debug)
if(_is_release)
    set(configuration_type "Release")
elseif(_is_debug)
    set(configuration_type "Debug")
else()
    hunter_user_error("Invalid build configuration type provided. Valid configuration types are: Release or Debug")
endif()


# Check Shared Lib
if(BUILD_SHARED_LIBS)
    string(CONCAT ${configuration_type} ${configuration_type} "DLL")
endif()


# Print MSVC Values
if(HUNTER_STATUS_DEBUG)
    hunter_status_debug("------- libsodium MSBuild values -------")
    hunter_status_debug("Platform Toolset:            ${msvc_platform_toolset}")
    hunter_status_debug("Architechture:               ${msvc_arch}")
    hunter_status_debug("Build Configuration:         @HUNTER_PACKAGE_CONFIGURATION_TYPES@")
    hunter_status_debug("MSBuild Build Configuration: ${configuration_type}")
endif()


# ExternalProject
ExternalProjectAdd("@HUNTER_EP_NAME@"
    URL
        @HUNTER_PACKAGE_URL@
    URL_HASH
        SHA1=@HUNTER_PACKAGE_SHA1@
    DOWNLOAD_DIR
        "@HUNTER_PACKAGE_DOWNLOAD_DIR@"
    SOURCE_DIR
        "@HUNTER_PACKAGE_SOURCE_DIR@"
    INSTALL_DIR
        "@HUNTER_PACKAGE_INSTALL_PREFIX@"
        # not used, just avoid creating Install/<name> empty directory
    CONFIGURE_COMMAND
        ""
    BUILD_COMMAND
        "msbuild /p:PlatformToolset:${msvc_platform_toolset} /p:Configuration:${configuration_type} /p:PostBuildEventUseInBuild=false"
    BUILD_IN_SOURCE
        1
    INSTALL_COMMAND
        #"${CMAKE_COMMAND} -E make_directory @HUNTER_PACKAGE_INSTALL_PREFIX@" &&
        "${CMAKE_COMMAND} -E copy_directory Build\\${configuration_type}\\${msvc_arch} @HUNTER_PACKAGE_INSTALL_PREFIX@\\lib" &&
        "${CMAKE_COMMAND} -E copy_directory src\\libsodium\\include @HUNTER_PACKAGE_INSTALL_PREFIX@\\include" &&
        "${CMAKE_COMMAND} -E remove_directory @HUNTER_PACKAGE_INSTALL_PREFIX@\\lib\\Intermediate" &&
        "${CMAKE_COMMAND} -E remove @HUNTER_PACKAGE_INSTALL_PREFIX@\\include\\Makefile.am"
)







