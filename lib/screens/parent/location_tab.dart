import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/child_model.dart';
import '../../models/device_model.dart';
import '../../models/location_model.dart';
import '../../models/safezone_model.dart';
import '../../services/child_service.dart';
import '../../services/location_service.dart';
import '../../services/safezone_service.dart';
import '../../widgets/custom_text_field.dart';

class LocationTab extends StatefulWidget {
  const LocationTab({super.key});

  @override
  State<LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> {
  final MapController _mapController = MapController();

  List<ChildModel> _children = [];
  ChildModel? _selectedChild;
  DeviceModel? _selectedDevice;

  LocationModel? _latestLocation;
  List<SafeZoneModel> _safeZones = [];
  bool _isLoading = true;
  bool _isRefreshingLocation = false;
  Timer? _autoRefreshTimer;

  // Tọa độ tâm mặc định (TP.HCM) nếu chưa có GPS
  final LatLng _defaultCenter = const LatLng(10.7769, 106.7009);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // Tự động làm mới vị trí thời gian thực mỗi 15 giây
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _selectedDevice != null && !_isRefreshingLocation) {
        _refreshLocation(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final children = await ChildService.getChildren();
      _children = children;
      if (children.isNotEmpty) {
        _selectedChild = children.first;
        if (_selectedChild!.devices.isNotEmpty) {
          _selectedDevice = _selectedChild!.devices.first;
        }
      }
      await _loadDeviceDetails();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadDeviceDetails() async {
    if (_selectedChild == null) return;

    try {
      final safeZones = await SafeZoneService.getSafeZones(
        childProfileId: _selectedChild!.id,
      );
      _safeZones = safeZones;

      if (_selectedDevice != null) {
        final loc = await LocationService.getLatestLocation(_selectedDevice!.id);
        _latestLocation = loc;
        if (loc != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              _mapController.move(LatLng(loc.latitude, loc.longitude), 15.0);
            } catch (_) {}
          });
        }
      } else {
        _latestLocation = null;
      }
    } catch (e) {
      debugPrint('[LocationTab] _loadDeviceDetails error: $e');
    }
    if (mounted) setState(() {});
  }

  Future<void> _refreshLocation({bool silent = false}) async {
    if (_selectedDevice == null) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có thiết bị nào được chọn')),
        );
      }
      return;
    }
    if (!silent) setState(() => _isRefreshingLocation = true);
    try {
      final loc = await LocationService.getLatestLocation(_selectedDevice!.id);
      if (mounted) {
        setState(() => _latestLocation = loc);
        if (loc != null) {
          try {
            _mapController.move(LatLng(loc.latitude, loc.longitude), 15.0);
          } catch (_) {}
          if (!silent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✓ Đã cập nhật vị trí mới nhất!'), backgroundColor: Colors.green),
            );
          }
        } else if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thiết bị chưa gửi tọa độ GPS nào lên hệ thống')),
          );
        }
      }
    } catch (e) {
      debugPrint('[LocationTab] _refreshLocation error: $e');
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải vị trí: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (!silent && mounted) setState(() => _isRefreshingLocation = false);
  }

  // Tạo hoặc chỉnh sửa Vùng An Toàn với chọn tâm và bán kính
  void _showSafeZoneDialog({SafeZoneModel? editingZone}) {
    if (_selectedChild == null) return;

    final isEditing = editingZone != null;
    final nameController = TextEditingController(
      text: isEditing ? editingZone.name : 'Trường học',
    );
    double initialLat = isEditing
        ? editingZone.latitude
        : (_latestLocation?.latitude ?? _defaultCenter.latitude);
    double initialLng = isEditing
        ? editingZone.longitude
        : (_latestLocation?.longitude ?? _defaultCenter.longitude);
    double selectedRadius = isEditing ? editingZone.radius : 500.0;
    bool isActive = isEditing ? editingZone.isActive : true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(isEditing ? 'Chỉnh sửa Vùng An Toàn' : 'Tạo Vùng An Toàn Trên Bản Đồ'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: nameController,
                    label: 'Tên vùng (Nhà, Trường học, CLB...)',
                    prefixIcon: Icons.shield_outlined,
                  ),
                  const SizedBox(height: 12),
                  // Thông tin tâm
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.place, color: Colors.blueAccent, size: 18),
                            SizedBox(width: 6),
                            Text('Tọa độ tâm vùng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vĩ độ: ${initialLat.toStringAsFixed(6)}\nKinh độ: ${initialLng.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        if (_latestLocation != null)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                            icon: const Icon(Icons.my_location, size: 14),
                            label: const Text('Lấy vị trí hiện tại của bé'),
                            onPressed: () {
                              setModalState(() {
                                initialLat = _latestLocation!.latitude;
                                initialLng = _latestLocation!.longitude;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Cấu hình Bán kính
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bán kính an toàn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${selectedRadius.toInt()} mét', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: selectedRadius,
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    label: '${selectedRadius.toInt()} m',
                    activeColor: Colors.blueAccent,
                    onChanged: (val) {
                      setModalState(() => selectedRadius = val);
                    },
                  ),
                  const SizedBox(height: 6),
                  // Cấu hình cảnh báo
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Kích hoạt vùng này', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Gửi thông báo khi trẻ di chuyển ra ngoài vùng', style: TextStyle(fontSize: 11)),
                    value: isActive,
                    // ignore: deprecated_member_use
                    activeColor: Colors.blueAccent,
                    onChanged: (val) {
                      setModalState(() => isActive = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final messenger = ScaffoldMessenger.of(context);

                  Navigator.pop(ctx);
                  try {
                    if (isEditing) {
                      await SafeZoneService.updateSafeZone(
                        id: editingZone.id,
                        name: name,
                        latitude: initialLat,
                        longitude: initialLng,
                        radius: selectedRadius,
                        isActive: isActive,
                      );
                    } else {
                      await SafeZoneService.createSafeZone(
                        name: name,
                        latitude: initialLat,
                        longitude: initialLng,
                        radius: selectedRadius,
                        childProfileId: _selectedChild!.id,
                      );
                    }
                    await _loadDeviceDetails();
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Đã cập nhật vùng an toàn!' : 'Đã tạo vùng an toàn thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Lưu thay đổi' : 'Xác nhận tạo vùng'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLocationHistoryDialog() async {
    if (_selectedDevice == null) return;

    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<List<LocationModel>>(
        future: LocationService.getLocationHistory(_selectedDevice!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          final list = snapshot.data ?? [];
          return AlertDialog(
            title: const Text('Lịch sử di chuyển thiết bị'),
            content: SizedBox(
              width: double.maxFinite,
              height: 350,
              child: list.isEmpty
                  ? const Center(child: Text('Chưa có dữ liệu lịch sử'))
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final loc = list[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on, color: Colors.blueAccent),
                          title: Text(
                            'Lat: ${loc.latitude.toStringAsFixed(5)}, Lng: ${loc.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Text(
                            'Lúc: ${loc.recordedAt.hour.toString().padLeft(2, '0')}:${loc.recordedAt.minute.toString().padLeft(2, '0')} ngày ${loc.recordedAt.day}/${loc.recordedAt.month}/${loc.recordedAt.year}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_children.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Chưa có hồ sơ trẻ nào. Vui lòng thêm hồ sơ trẻ tại tab "Con cái".',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final childLatLng = _latestLocation != null
        ? LatLng(_latestLocation!.latitude, _latestLocation!.longitude)
        : _defaultCenter;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Dropdown chọn trẻ & thiết bị
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_pin_circle, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        const Text('Chọn Trẻ:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ChildModel>(
                              isExpanded: true,
                              value: _selectedChild,
                              items: _children.map((c) {
                                return DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)));
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedChild = val;
                                  _selectedDevice = (val != null && val.devices.isNotEmpty) ? val.devices.first : null;
                                });
                                _loadDeviceDetails();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedChild != null) ...[
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.phone_android,
                                size: 16,
                                color: _selectedDevice != null ? Colors.teal : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedDevice != null
                                    ? 'Thiết bị: ${_selectedDevice!.name}'
                                    : 'Chưa có thiết bị nào ghép nối',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedDevice != null ? Colors.black87 : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedChild!.devices.length > 1)
                            DropdownButton<DeviceModel>(
                              value: _selectedDevice,
                              underline: const SizedBox(),
                              items: _selectedChild!.devices.map((d) {
                                return DropdownMenuItem(value: d, child: Text(d.name, style: const TextStyle(fontSize: 12)));
                              }).toList(),
                              onChanged: (d) {
                                setState(() => _selectedDevice = d);
                                _loadDeviceDetails();
                              },
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Thẻ hiển thị vị trí trên bản đồ thực tế & cập nhật thời gian thực
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.map, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Text(
                              'Bản đồ vị trí ${_selectedChild?.name ?? ""}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: _isRefreshingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh, color: Colors.blueAccent),
                          tooltip: 'Cập nhật vị trí ngay',
                          onPressed: () => _refreshLocation(),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    // Thời điểm cập nhật gần nhất
                    if (_latestLocation != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 15, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Cập nhật lúc: ${_latestLocation!.recordedAt.hour.toString().padLeft(2, '0')}:${_latestLocation!.recordedAt.minute.toString().padLeft(2, '0')}:${_latestLocation!.recordedAt.second.toString().padLeft(2, '0')} ngày ${_latestLocation!.recordedAt.day}/${_latestLocation!.recordedAt.month}',
                                style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Text(
                            'Vĩ độ: ${_latestLocation!.latitude.toStringAsFixed(4)} | ${_latestLocation!.longitude.toStringAsFixed(4)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'Chưa nhận được vị trí thời gian thực từ thiết bị trẻ.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    const SizedBox(height: 10),

                    // Khung Bản đồ thực tế OpenStreetMap
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: childLatLng,
                              initialZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.qltreem',
                              ),
                              // Vùng an toàn hiển thị dưới dạng vòng tròn bán kính thực tế trên bản đồ
                              CircleLayer(
                                circles: _safeZones.map((z) {
                                  return CircleMarker(
                                    point: LatLng(z.latitude, z.longitude),
                                    radius: z.radius,
                                    useRadiusInMeter: true,
                                    color: z.isActive
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Colors.grey.withValues(alpha: 0.15),
                                    borderColor: z.isActive ? Colors.green : Colors.grey,
                                    borderStrokeWidth: 2,
                                  );
                                }).toList(),
                              ),
                              // Marker định vị Trẻ
                              if (_latestLocation != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: childLatLng,
                                      width: 80,
                                      height: 80,
                                      child: Column(
                                        children: [
                                          const Icon(Icons.person_pin, color: Colors.red, size: 40),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black87,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _selectedChild?.name ?? 'Bé',
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          // Nút căn giữa vào vị trí Trẻ
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: FloatingActionButton.small(
                              heroTag: 'recenter_parent_map',
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blueAccent,
                              onPressed: () {
                                if (_latestLocation != null) {
                                  _mapController.move(childLatLng, 15.0);
                                }
                              },
                              child: const Icon(Icons.my_location),
                            ),
                          ),
                          // Chú thích vùng an toàn
                          if (_safeZones.isNotEmpty)
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Text(
                                  '🟢 ${_safeZones.length} Vùng an toàn',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ),
                            ),
                          // Thông báo khi thiết bị chưa gửi GPS
                          if (_latestLocation == null)
                            Positioned(
                              top: _safeZones.isNotEmpty ? 42 : 10,
                              left: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.amber.shade400),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Thiết bị ${_selectedDevice?.name ?? ""} chưa gửi GPS lên hệ thống. Hãy mở máy Trẻ vào tab "GPS của con" và bấm "Gửi vị trí GPS".',
                                        style: TextStyle(fontSize: 11.5, color: Colors.brown.shade800, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text('Xem lịch sử lộ trình'),
                          onPressed: _showLocationHistoryDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Vùng An Toàn: Tạo vùng trên bản đồ, chỉnh sửa, xóa, cấu hình cảnh báo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Vùng An Toàn Của Trẻ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.add_location_alt, size: 18),
                  label: const Text('Tạo vùng mới'),
                  onPressed: () => _showSafeZoneDialog(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_safeZones.isEmpty)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'Chưa thiết lập vùng an toàn nào cho bé này.\nBấm "Tạo vùng mới" để nhận cảnh báo ngay khi con rời khỏi vùng an toàn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ),
              )
            else
              ..._safeZones.map(
                (zone) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: zone.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                      child: Icon(Icons.home, color: zone.isActive ? Colors.green : Colors.grey),
                    ),
                    title: Row(
                      children: [
                        Text(zone.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (!zone.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Tạm tắt', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      'Tâm: ${zone.latitude.toStringAsFixed(4)}, ${zone.longitude.toStringAsFixed(4)}\nBán kính: ${zone.radius.toInt()} mét | Cảnh báo khi rời vùng',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nút Chỉnh sửa vùng
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                          tooltip: 'Chỉnh sửa vùng',
                          onPressed: () => _showSafeZoneDialog(editingZone: zone),
                        ),
                        // Nút Xóa vùng
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Xóa vùng',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Xóa vùng an toàn "${zone.name}"?'),
                                content: const Text('Hệ thống sẽ không gửi cảnh báo cho vùng này nữa.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await SafeZoneService.deleteSafeZone(zone.id);
                              _loadDeviceDetails();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
