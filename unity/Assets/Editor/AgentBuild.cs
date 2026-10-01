// Headless build entry point for checking an agent's work.
// Copy this file into Assets/Editor/ of your Unity project, then run:
//   Unity -batchmode -quit -projectPath <worktree> -executeMethod AgentBuild.Build -logFile <log>
// Optional: -buildPath <folder>   (default: Builds/agent-check)
// Exit code 0 = build succeeded, 1 = build failed.
using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

public static class AgentBuild
{
    public static void Build()
    {
        var scenes = EditorBuildSettings.scenes.Where(s => s.enabled).Select(s => s.path).ToArray();
        if (scenes.Length == 0)
        {
            Debug.LogError("AgentBuild: no enabled scenes in Build Settings.");
            EditorApplication.Exit(1);
            return;
        }

        var target = EditorUserBuildSettings.activeBuildTarget;
        var outDir = Arg("-buildPath") ?? Path.Combine("Builds", "agent-check");
        var options = new BuildPlayerOptions
        {
            scenes = scenes,
            target = target,
            locationPathName = Path.Combine(outDir, PlayerFileName(target)),
            options = BuildOptions.None,
        };

        var report = BuildPipeline.BuildPlayer(options);
        var s = report.summary;
        Debug.Log($"AgentBuild: {s.result} for {target}, {s.totalErrors} errors, {s.totalWarnings} warnings, {s.totalTime}.");
        EditorApplication.Exit(s.result == BuildResult.Succeeded ? 0 : 1);
    }

    static string PlayerFileName(BuildTarget target)
    {
        var name = string.IsNullOrEmpty(PlayerSettings.productName) ? "Game" : PlayerSettings.productName;
        switch (target)
        {
            case BuildTarget.StandaloneWindows:
            case BuildTarget.StandaloneWindows64: return name + ".exe";
            case BuildTarget.StandaloneOSX: return name + ".app";
            case BuildTarget.Android: return name + ".apk";
            default: return name;
        }
    }

    static string Arg(string name)
    {
        var args = Environment.GetCommandLineArgs();
        var i = Array.IndexOf(args, name);
        return i >= 0 && i + 1 < args.Length ? args[i + 1] : null;
    }
}
