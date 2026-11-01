import AppKit
import Darwin
import IOKit.ps

struct MachineSnapshot {
    var cpu: Double? = nil
    var memoryGB: Double = 0
    var totalMemoryGB: Double = 0
    var battery: Int? = nil
    var charging = false
    var externalPower = false
    var diskFreeGB: Double = 0
    var cpuHistory: [Double] = []
}
final class SystemMonitor {
    private var previous: [UInt32]?
    private var history: [Double] = []
    func sample() -> MachineSnapshot {
        var snapshot = MachineSnapshot()
        var load = host_cpu_load_info(); var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &load) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count) }
        }
        if result == KERN_SUCCESS {
            let ticks = [load.cpu_ticks.0, load.cpu_ticks.1, load.cpu_ticks.2, load.cpu_ticks.3]
            if let previous {
                let delta = zip(ticks, previous).map { UInt64($0 &- $1) }
                let total = delta.reduce(0, +)
                if total > 0 { snapshot.cpu = 100 * (1 - Double(delta[Int(CPU_STATE_IDLE)]) / Double(total)) }
            }
            previous = ticks
        }
        if let cpu = snapshot.cpu { history.append(cpu); if history.count > 40 { history.removeFirst() } }
        snapshot.cpuHistory = history
        var vm = vm_statistics64(); var vmCount = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let memoryResult = withUnsafeMutablePointer(to: &vm) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(vmCount)) { host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &vmCount) }
        }
        snapshot.totalMemoryGB = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824
        if memoryResult == KERN_SUCCESS {
            let pages = UInt64(vm.active_count) + UInt64(vm.wire_count) + UInt64(vm.compressor_page_count)
            snapshot.memoryGB = min(snapshot.totalMemoryGB, Double(pages) * Double(vm_kernel_page_size) / 1_073_741_824)
        }
        if let source = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(), let list = IOPSCopyPowerSourcesList(source)?.takeRetainedValue() as? [CFTypeRef] {
            for item in list {
                guard let detail = IOPSGetPowerSourceDescription(source, item)?.takeUnretainedValue() as? [String: Any],
                      detail[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
                      let current = detail[kIOPSCurrentCapacityKey] as? Int, let max = detail[kIOPSMaxCapacityKey] as? Int, max > 0 else { continue }
                snapshot.battery = min(100, Int(Double(current) / Double(max) * 100))
                snapshot.charging = detail[kIOPSIsChargingKey] as? Bool ?? false
                snapshot.externalPower = detail[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
                break
            }
        }
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: FileManager.default.homeDirectoryForCurrentUser.path), let free = attrs[.systemFreeSize] as? NSNumber { snapshot.diskFreeGB = free.doubleValue / 1_073_741_824 }
        return snapshot
    }
}
