import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as map;
import 'package:image/image.dart' as img;

class ImagePickerPage extends StatefulWidget {
  final Function(img.Image, map.LatLng?)? onImageSelected;
  final String actionText;
  final Widget title;
  final double? ratio;
  const ImagePickerPage({
    Key? key,
    required this.title,
    this.onImageSelected,
    this.ratio,
    this.actionText = '次へ',
  }) : super(key: key);

  @override
  _ImagePickerPageState createState() => _ImagePickerPageState();
}

class _GridStatusNotifier {
  final Rect imageRect;
  double opacity;
  _GridStatusNotifier(this.imageRect, this.opacity);
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  static const double _MAX_CROP_RATIO = 5 / 4; // height / width
  static const double _MIN_CROP_RATIO = 1 / 1.91;

  List<AssetPathEntity>? directories;
  AssetPathEntity? selectedDirectory;
  List<AssetEntity>? images;
  AssetEntity? selectedImage;

  final GlobalKey<ExtendedImageGestureState> _gestureKey = GlobalKey<ExtendedImageGestureState>();
  final gridStatus = ValueNotifier<_GridStatusNotifier?>(null);
  Timer? gridTimer;

  @override
  void initState() {
    super.initState();
    getImagesPath();
  }

  getImagesPath() async {
    directories = await PhotoManager.getAssetPathList(type: RequestType.image);
    selectedDirectory = directories?.firstWhere((d) => d.isAll);
    images = await selectedDirectory?.getAssetListPaged(page: 0, size: 100);
    selectedImage = images?.first;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.title,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () async {
              final executer = () async {
                final imageLocation = await pickLocationFromAsset(selectedImage!);

                final gestureDetails = _gestureKey.currentState!.gestureDetails;
                final file = await selectedImage!.file;
                final data = file!.readAsBytesSync();
                final src = img.decodeImage(data)!;

                final cropArea = computeCropRect(
                  src,
                  destinationRect: gestureDetails!.destinationRect!,
                  cropAreaRect: gestureDetails.layoutRect!,
                );

                final croppedImage = cropImage(src, cropArea);
                final resizedImage = img.copyResize(croppedImage, width: 1080);
                widget.onImageSelected?.call(resizedImage, imageLocation);
              };

              showGeneralDialog(
                context: context,
                barrierDismissible: false,
                transitionDuration: Duration(milliseconds: 300),
                barrierColor: Colors.black.withOpacity(0.5),
                pageBuilder: (BuildContext context, Animation animation, Animation secondaryAnimation) {
                  executer().then((_) => Navigator.of(context).pop());
                  return Center(child: CircularProgressIndicator());
                },
              );
            },
            child: Text('完了'),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.width,
            color: Colors.black,
            child: Stack(
              children: [
                selectedImage != null
                    ? FutureBuilder<Uint8List?>(
                        future: selectedImage!.thumbnailDataWithSize(ThumbnailSize(1200, 1200)),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return CustomPaint(
                              foregroundPainter: GridPainter(repaint: gridStatus),
                              child: Listener(
                                onPointerDown: (_) => {startShowGrid()},
                                onPointerUp: (_) => {endShowGrid()},
                                child: ExtendedImage.memory(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                  constraints: BoxConstraints.expand(),
                                  mode: ExtendedImageMode.gesture,
                                  extendedImageGestureKey: _gestureKey,
                                  initGestureConfigHandler: (state) {
                                    final image = state.extendedImageInfo!.image;
                                    final ratio = image.height / image.width;
                                    final initialScale = max(ratio, 1 / ratio).toDouble();

                                    final minimumScale;
                                    if (widget.ratio == null) {
                                      final needCrop = ratio > _MAX_CROP_RATIO || ratio < _MIN_CROP_RATIO;
                                      minimumScale = max(
                                          needCrop
                                              ? (ratio > _MAX_CROP_RATIO
                                                  ? initialScale / _MAX_CROP_RATIO
                                                  : initialScale * _MIN_CROP_RATIO)
                                              : 1.0,
                                          1.0);
                                    } else {
                                      final needCrop = ratio > widget.ratio! || ratio < widget.ratio!;
                                      minimumScale = max(
                                          needCrop
                                              ? (ratio > widget.ratio!
                                                  ? initialScale / widget.ratio!
                                                  : initialScale * widget.ratio!)
                                              : 1.0,
                                          1.0);
                                    }

                                    return GestureConfig(
                                      minScale: minimumScale,
                                      initialScale: initialScale,
                                      animationMinScale: minimumScale * 0.85,
                                    );
                                  },
                                ),
                              ),
                            );
                          } else {
                            return Container();
                          }
                        })
                    : Container(),
                Positioned(
                  left: 5,
                  bottom: 5,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.black.withAlpha(160),
                      padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                      minimumSize: Size(0, 0),
                    ),
                    onPressed: () => showFolderList(),
                    icon: Icon(
                      Icons.folder,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      selectedDirectory?.name ?? 'loading...',
                    ),
                  ),
                ),
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.black.withAlpha(160),
                      padding: EdgeInsets.all(5),
                      minimumSize: Size(0, 0),
                    ),
                    onPressed: () => showImageList(),
                    child: Icon(
                      Icons.grid_view,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                )
              ],
            ),
          ),
          Divider(height: 2),
          Expanded(
            child: Container(
              color: Colors.white,
              child: GridImageList(
                images: images ?? [],
                onSelected: (asset) {
                  setState(() => {selectedImage = asset});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  showImageList() {
    showCupertinoModalBottomSheet(
      context: context,
      duration: Duration(milliseconds: 200),
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text('画像選択'),
            // automaticallyImplyLeading: false,
            automaticallyImplyLeading: true,
            leading: GestureDetector(
              onTap: () => {Navigator.of(context).pop()},
              child: Transform.rotate(angle: pi / 4, child: Icon(Icons.add, size: 40)),
            ),
          ),
          body: GridImageList(
            images: images!,
            onSelected: (asset) {
              setState(() => {selectedImage = asset});
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  showFolderList() {
    showCupertinoModalBottomSheet(
      context: context,
      duration: Duration(milliseconds: 200),
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text('アルバムの選択'),
            // automaticallyImplyLeading: false,
            automaticallyImplyLeading: true,
            leading: GestureDetector(
              onTap: () => {Navigator.of(context).pop()},
              child: Transform.rotate(angle: pi / 4, child: Icon(Icons.add, size: 40)),
            ),
          ),
          body: FolderList(
            directories: directories!,
            onSelected: (directory) async {
              Navigator.of(context).pop();

              selectedDirectory = directory;
              images = await directory.getAssetListPaged(page: 0, size: 100);
              selectedImage = images!.first;
              setState(() {});
            },
          ),
        );
      },
    );
  }

  List<DropdownMenuItem<AssetPathEntity>> getItems() {
    if (directories == null) return [];
    return directories!.map((directory) {
      return DropdownMenuItem(
        child: Text(directory.name),
        value: directory,
      );
    }).toList();
  }

  startShowGrid() {
    final gesture = _gestureKey.currentState;
    if (gesture == null) return;

    gridTimer?.cancel();
    gridTimer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      final rectOnScreen = gesture.gestureDetails!.destinationRect!.intersect(gesture.gestureDetails!.layoutRect!);
      gridStatus.value = _GridStatusNotifier(rectOnScreen.translate(0, -gesture.gestureDetails!.layoutRect!.top), 1);
    });
  }

  endShowGrid() {
    gridTimer?.cancel();
    Timer.periodic(Duration(milliseconds: 10), (timer) {
      if (timer.tick <= 30) {
        final gesture = _gestureKey.currentState;
        if (gesture?.gestureDetails?.destinationRect == null) return;
        final rectOnScreen = gesture!.gestureDetails!.destinationRect!.intersect(gesture.gestureDetails!.layoutRect!);
        final rect = rectOnScreen.translate(0, -gesture.gestureDetails!.layoutRect!.top);
        gridStatus.value = _GridStatusNotifier(rect, 1 - 0.03 * timer.tick);
      } else {
        timer.cancel();
        gridStatus.value = null;
      }
    });
  }

  Future<map.LatLng?> pickLocationFromAsset(AssetEntity asset) async {
    final latlng = await asset.latlngAsync();

    if (latlng.latitude == null && latlng.longitude == null) {
      return null;
    } else if (latlng.latitude == 0 && latlng.longitude == 0) {
      return null;
    } else {
      return map.LatLng(latlng.latitude!, latlng.longitude!);
    }
  }

  Rect computeCropRect(
    img.Image original, {
    required Rect destinationRect,
    required Rect cropAreaRect,
  }) {
    final scaling = original.width / destinationRect.width;
    final stdDestination = destinationRect.shift(-destinationRect.topLeft);
    final stdLayout = cropAreaRect.shift(-destinationRect.topLeft);
    final intersect = stdDestination.intersect(stdLayout);
    return Rect.fromPoints(intersect.topLeft * scaling, intersect.bottomRight * scaling);
  }

  img.Image cropImage(img.Image original, Rect cropRect) {
    return img.copyCrop(
      original,
      cropRect.topLeft.dx.toInt(),
      cropRect.topLeft.dy.toInt(),
      cropRect.width.toInt(),
      cropRect.height.toInt(),
    );
  }
}

class GridImageList extends StatelessWidget {
  final List<AssetEntity> images;
  final void Function(AssetEntity) onSelected;
  const GridImageList({
    Key? key,
    required this.images,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 2, mainAxisSpacing: 2),
      itemBuilder: (_, i) {
        return FutureBuilder<Uint8List?>(
          future: images[i].thumbnailData,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return GestureDetector(
                child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                onTap: () {
                  onSelected(images[i]);
                },
              );
            } else {
              return Container();
            }
          },
        );
      },
      itemCount: images.length,
    );
  }
}

class FolderList extends StatelessWidget {
  static const _ITEM_HEIGHT = 85.0;
  static const _IMAGE_SIZE = 80.0;
  static const _ITEM_PADDING = (_ITEM_HEIGHT - _IMAGE_SIZE) / 2;
  final List<AssetPathEntity> directories;
  final void Function(AssetPathEntity) onSelected;
  const FolderList({Key? key, required this.directories, required this.onSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(5),
      itemBuilder: (context, index) {
        final directory = directories[index];
        final topImageLoader = () async {
          final assetsFuture = await directory.getAssetListRange(start: 0, end: 1);
          final imageData = await assetsFuture[0].thumbnailData;
          return imageData!;
        };

        return InkWell(
          onTap: () => onSelected(directory),
          child: Container(
            height: _ITEM_HEIGHT,
            padding: const EdgeInsets.only(top: _ITEM_PADDING, bottom: _ITEM_PADDING),
            child: Row(
              children: [
                FutureBuilder<Uint8List>(
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(snapshot.data!, width: _IMAGE_SIZE, height: _IMAGE_SIZE, fit: BoxFit.cover);
                    } else {
                      return SizedBox(width: 60, child: Center(child: CircularProgressIndicator()));
                    }
                  },
                  future: topImageLoader(),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(directory.name, style: TextStyle(fontSize: 16)),
                    Text(directory.assetCount.toString()),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      itemCount: directories.length,
    );
  }
}

class GridPainter extends CustomPainter {
  ValueNotifier<_GridStatusNotifier?>? _repaint;

  GridPainter({ValueNotifier<_GridStatusNotifier?>? repaint}) : super(repaint: repaint) {
    this._repaint = repaint;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final data = _repaint?.value;
    if (data == null) return;
    final imageRect = data.imageRect;
    final paint = Paint();
    final left = imageRect.left;
    final right = imageRect.right;
    final top = imageRect.top;
    final bottom = imageRect.bottom;
    final width = imageRect.width;
    final height = imageRect.height;
    final x1 = left + width * 1 / 3;
    final x2 = left + width * 2 / 3;
    final y1 = top + height * 1 / 3;
    final y2 = top + height * 2 / 3;

    paint.color = Colors.grey.shade300.withOpacity(data.opacity);
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 0.5);
    paint.strokeWidth = 1;
    canvas.drawLine(Offset(x1, top), Offset(x1, bottom), paint);
    canvas.drawLine(Offset(x2, top), Offset(x2, bottom), paint);
    canvas.drawLine(Offset(left, y1), Offset(right, y1), paint);
    canvas.drawLine(Offset(left, y2), Offset(right, y2), paint);

    paint.color = Colors.white.withOpacity(data.opacity);
    paint.maskFilter = null;
    paint.strokeWidth = 0.5;
    canvas.drawLine(Offset(x1, top), Offset(x1, bottom), paint);
    canvas.drawLine(Offset(x2, top), Offset(x2, bottom), paint);
    canvas.drawLine(Offset(left, y1), Offset(right, y1), paint);
    canvas.drawLine(Offset(left, y2), Offset(right, y2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
