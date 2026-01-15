// ignore_for_file: use_key_in_widget_constructors, camel_case_types, file_names, unused_field, deprecated_member_use, unused_local_variable

import 'dart:ui';
import 'package:flutter/material.dart';

class notificationsScrollTest extends StatefulWidget {

  @override
  State<notificationsScrollTest> createState() => _notificationsScrollTestState();
}

class _notificationsScrollTestState extends State<notificationsScrollTest> {
  static const double itemHeight = 70;
  static const double spacing = 0;
  static const double itemExtent = itemHeight + spacing;

  final ScrollController _controller = ScrollController();

  final List<String> data = [
    "You paid Zoom for monthly subscription aaaaaaaaaaaa",
    "Transferred \$500,000 to Sara",
    "Netflix subscription updated",
    "Invoice paid successfully",
    "Deposit received",
    "Spotify plan renewed",
  ];

  @override
  Widget build(BuildContext context) {
    final centerPadding =
        MediaQuery.of(context).size.height / 2 - itemHeight / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            _snap();
          }
          setState(() {});
          return true;
        },
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          controller: _controller,
          padding: EdgeInsets.symmetric(vertical: centerPadding),
          itemCount: data.length,
          itemBuilder: (context, index) {
            double currentScroll = _controller.hasClients
                ? _controller.offset
                : 0;
            double itemOffset = index * itemExtent;
            double center = centerPadding;

            double progress = currentScroll / itemExtent;
            double diff = (index - progress).abs();

            //if (diff > 2.4) return const SizedBox.shrink();
            bool hidden = diff > 2.4;

            // profundidad continua (0, 1, 2)
            double depth = diff.clamp(0.0, 2.0);

            // 🔹 desplazamiento por capa
            double translateY = depth * -13;

            // 🔹 escala por profundidad
            double scale = 1 - depth * 0.08;

            // 🔹 opacidad por capa
            double opacity = 1 - depth * 0.4;

            return IgnorePointer(
              ignoring: hidden,
              child: Opacity(
                opacity: hidden ? 0 : opacity,
                child: Transform.translate(
                  offset: Offset(0, translateY),
                  child: Transform.scale(
                    scale: scale,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: hidden ? 13 : depth * 2,
                          sigmaY: hidden ? 13 : depth * 2,
                        ),
                        child: Container(
                          height: itemHeight,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: spacing / 2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 15,
                                color: Colors.black45,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.blue,
                                child: Icon(
                                  Icons.notifications,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),

                              // TEXTO PRINCIPAL
                              Expanded(
                                child: Text(
                                  data[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              const SizedBox(width: 8),

                              // TIEMPO
                              Text(
                                "5 minutes ago",
                                style: TextStyle(
                                  color: Colors.white60.withOpacity(0.3),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),

                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );

          },
        ),
      ),
    );
  }

  void _snap() {
    double index = (_controller.offset / itemExtent).roundToDouble();
    double target = index * itemExtent;

    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

