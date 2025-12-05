import 'package:flutter/material.dart';
import 'package:school_test/screens/add_school/services/location_service.dart';

/// Widget for location picking with automatic fetching
class LocationPickerWidget extends StatefulWidget {
  final TextEditingController addressController;
  final Function(double, double) onLocationFetched;

  const LocationPickerWidget({
    Key? key,
    required this.addressController,
    required this.onLocationFetched,
  }) : super(key: key);

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  bool _isLoading = false;
  bool _locationFetched = false;
  String? _latitude;
  String? _longitude;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-fetch location on widget load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLocation();
    });
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoading = true;
      _locationFetched = false;
      _errorMessage = null;
    });

    try {
      final locationData = await LocationService.getCurrentLocation();

      setState(() {
        _latitude = locationData.latitude.toStringAsFixed(6);
        _longitude = locationData.longitude.toStringAsFixed(6);
        widget.addressController.text = locationData.address;
        _locationFetched = true;
        _isLoading = false;
      });

      widget.onLocationFetched(locationData.latitude, locationData.longitude);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            action: e.toString().contains('permanently')
                ? SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () => LocationService.openSettings(),
                  )
                : null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _locationFetched
              ? Colors.green
              : (_isLoading ? Colors.blue[300]! : Colors.grey[300]!),
          width: _locationFetched ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Row
          if (_isLoading)
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Fetching your location...',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else if (_locationFetched)
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 22),
                SizedBox(width: 8),
                Text(
                  'Location fetched successfully',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.blue[700], size: 22),
                  onPressed: _fetchLocation,
                  tooltip: 'Refresh location',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(Icons.location_off, color: Colors.orange, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage ?? 'Unable to fetch location',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _fetchLocation,
                  icon: Icon(Icons.refresh, size: 18),
                  label: Text('Retry'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),

          // Coordinates Display
          if (_latitude != null && _longitude != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _locationFetched ? Colors.green[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _locationFetched
                      ? Colors.green[200]!
                      : Colors.blue[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: _locationFetched
                        ? Colors.green[700]
                        : Colors.blue[700],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coordinates',
                          style: TextStyle(
                            fontSize: 12,
                            color: _locationFetched
                                ? Colors.green[700]
                                : Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Lat: $_latitude, Long: $_longitude',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Address TextField
            Text(
              'Address',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: widget.addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Address will appear here (editable)',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please get location or enter address manually';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }
}
