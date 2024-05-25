const std = @import("std");

const Path = std.Build.LazyPath;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const compileExample = b.option(bool, "example", "Enable example compilation") orelse false;

    const serial = b.addStaticLibrary(.{
        .name = "serial",
        .target = target,
        .optimize = optimize,
    });
    serial.addIncludePath(Path{ .path = "include" });
    serial.addCSourceFiles(.{
        .files = &.{
            "src/serial.cc",
        },
        .flags = &.{
            "-std=c++20",
            "-frtti",
            "-fexceptions",
            // "-fno-rtti",
            // "-fno-exceptions",
        },
    });
    if (target.query.os_tag == .windows) {
        serial.root_module.addCMacro("_WIN32", "");
        serial.addCSourceFiles(.{
            .files = &.{
                "src/impl/win.cc", "src/impl/list_ports/list_ports_win.cc",
            },
            .flags = &.{
                "-std=c++20",
                // "-fno-rtti",
                "-frtti",
                // "-fno-exceptions",
                "-fexceptions",
            },
        });
    } else {
        //Assume linux
        serial.addCSourceFiles(.{
            .files = &.{
                "src/impl/unix.cc",
                "src/impl/list_ports/list_ports_linux.cc",
            },
            .flags = &.{
                "-std=c++20",
                // "-fno-rtti",
                "-frtti",
                // "-fno-exceptions",
                "-fexceptions",
            },
        });
    }

    serial.installHeadersDirectory(b.path("include"), "", .{
        .include_extensions = &.{
            ".h",
        },
        .exclude_extensions = &.{
            "am",
            "gitignore",
        },
    });

    serial.linkLibCpp();
    b.installArtifact(serial);

    if (compileExample) {
        const exe = b.addExecutable(.{
            .name = "serial-sample",
            .target = target,
            .optimize = optimize,
        });
        exe.linkLibrary(serial);
        exe.linkLibCpp();
        exe.addIncludePath(.{ .path = "include" });

        if (target.query.os_tag == .windows)
            exe.root_module.addCMacro("_WIN32", "");
        exe.addCSourceFiles(.{ .files = &.{
            "examples/serial_example.cc",
        }, .flags = &.{
            "-std=c++20",
            "-frtti",
            "-fexceptions",
        } });
        b.installArtifact(exe);
    }
}
