const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast});

    const enable_global_fade = b.option(bool, "global-fade", "Use global SVG masking for fading instead of per-cell fading") orelse true;
    const options = b.addOptions();
    options.addOption(bool, "global_fade", enable_global_fade);

    const config_mod = options.createModule();

    const grid = b.createModule(.{
        .root_source_file = b.path("src/Grid.zig"),
        .target = target,
        .optimize = optimize,
    });

    const perlin = b.createModule(.{
        .root_source_file = b.path("src/perlin3d.zig"),
        .target = target,
        .optimize = optimize,
    });

    const root = b.addExecutable(.{
        .name = "tiler",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .strip = true,
            .target = target,
            .optimize = optimize,
        }),
    });

    const typ = b.dependency("typ", .{}).module("typ");
    const xml = b.dependency("xml", .{}).module("xml");
    const zbor_mod = b.dependency("zbor", .{}).module("zbor");

    grid.addImport("perlin", perlin);
    grid.addImport("config", config_mod);

    root.root_module.addImport("config", config_mod);
    root.root_module.addImport("grid", grid);
    root.root_module.addImport("typ", typ);
    root.root_module.addImport("xml", xml);
    root.root_module.addImport("perlin", perlin);
    root.root_module.addImport("zbor", zbor_mod);
    root.entry = .disabled;
    root.rdynamic = true;

    const install_tiler = b.addInstallArtifact(root, .{
        .dest_dir = .{ .override = .{ .custom = "../" } },
    });
    b.getInstallStep().dependOn(&install_tiler.step);

    const zon_content = @embedFile("build.zig.zon");
    const version_start = std.mem.indexOf(u8, zon_content, ".version = \"").? + 12;
    const version_end = std.mem.indexOfPos(u8, zon_content, version_start, "\"").?;
    const version = zon_content[version_start..version_end];

    const bash_cmd = b.addSystemCommand(&.{
        "bash",
        "-c",
        "mkdir -p ~/.local/share/typst/packages/local/tuileur && rm -rf ~/.local/share/typst/packages/local/tuileur/$1 && ln -s \"$PWD\" ~/.local/share/typst/packages/local/tuileur/$1",
        "bash",
        version,
    });
    bash_cmd.has_side_effects = true;

    const install_typst_step = b.step("install-local-typst", "Install symlink to Typst local packages");
    install_typst_step.dependOn(&bash_cmd.step);
}
