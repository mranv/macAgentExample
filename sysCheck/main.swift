//
//  main.swift
//  sysCheck
//
//  Created by Anubhav Gain on 14/03/24.
//

import Foundation

func main() {
   let brewPath = getPath(for: "brew")
   let osqueryPath = getPath(for: "osqueryi")
   let spctlPath = getPath(for: "spctl")
   let brewInstalled = brewPath != nil
   let (gatekeeperStatus, xprotectStatus) = checkGatekeeperXprotect(spctlPath: spctlPath)

   print("Homebrew is \(brewInstalled ? "" : "not ")installed.")
   print("osquery is \(osqueryPath != nil ? "" : "not ")installed.")
   print("GateKeeper is \(gatekeeperStatus).")
   print("XProtect is \(xprotectStatus).")
}

func getPath(for command: String) -> String? {
   let task = Process()
   task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
   task.arguments = [command]

   do {
       let outputPipe = Pipe()
       task.standardOutput = outputPipe
       let _ = try task.run()
       task.waitUntilExit()

       let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
       guard let path = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
           return nil
       }

       return path
   } catch {
       fatalError("Failed to execute 'which' command")
   }
}

func checkGatekeeperXprotect(spctlPath: String?) -> (String, String) {
   guard let spctlPath = spctlPath else {
       fatalError("spctl command not found")
   }
   let task = Process()
   task.executableURL = URL(fileURLWithPath: spctlPath)
   task.arguments = ["--status"]

   do {
       let outputPipe = Pipe()
       task.standardOutput = outputPipe
       let _ = try task.run()
       task.waitUntilExit()

       let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
       guard let outputString = String(data: outputData, encoding: .utf8) else {
           fatalError("Failed to read output from 'spctl' command")
       }

       let outputLines = outputString.components(separatedBy: "\n")

       let gatekeeperStatus = outputLines.contains("assessments enabled") ? "enabled" : "disabled"
       let xprotectStatus = outputLines.contains("File Protections: enabled") ? "enabled" : "disabled"

       return (gatekeeperStatus, xprotectStatus)
   } catch {
       fatalError("Failed to execute 'spctl' command")
   }
}

main()
