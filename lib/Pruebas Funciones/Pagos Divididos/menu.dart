// ignore_for_file: unused_local_variable, deprecated_member_use, sized_box_for_whitespace, prefer_interpolation_to_compose_strings, unused_element, use_key_in_widget_constructors, must_be_immutable, no_leading_underscores_for_local_identifiers, avoid_unnecessary_containers, collection_methods_unrelated_type, avoid_print

/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double userMoney = 13500.88; // Cambiá el valor para probar con o sin decimales

    double screenWidth = MediaQuery.of(context).size.width;

    // Formatea los movimientos como currency 
  String formatCurrencyMovimientos(double value, bool showDecimals) {
    final formatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '',
      decimalDigits: showDecimals ? 2 : 0,
    );
    return formatter.format(value);
  }

    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 83),
            child: Center(
              child: Text("Saldo", style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Center(child: MoneyCounter(amount: userMoney)),
          ),
          SizedBox(height: 43),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Container(
                    height: 63,
                    width: 63,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100)
                    ),
                    child: Icon(Icons.add_rounded, color: Colors.blueAccent, size: 33),
                  ),
                  SizedBox(height: 10),
                  Text("Ingresar", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                ],
              ),
              Column(
                children: [
                  Container(
                    height: 63,
                    width: 63,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100)
                    ),
                    child: Icon(Icons.arrow_forward, color: Colors.blueAccent, size: 33),
                  ),
                  SizedBox(height: 10),
                  Text("Enviar", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                ],
              ),
              Column(
                children: [
                  Container(
                    height: 63,
                    width: 63,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100)
                    ),
                    child: Icon(Icons.arrow_back, color: Colors.blueAccent, size: 33),
                  ),
                  SizedBox(height: 10),
                  Text("Cobrar", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                ],
              ),
            ],  
          ),
          SizedBox(height: 43),
          Expanded(
            child: Container(
              width: screenWidth,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.only(topRight: Radius.circular(50), topLeft: Radius.circular(50))
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 23, left: 33),
                    child: Align(alignment: Alignment.topLeft, child: Text("Mas formas de pagar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 23))),
                  ),
                  SizedBox(height: 23),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(13))
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // centra verticalmente
                      crossAxisAlignment: CrossAxisAlignment.center, // centra horizontalmente
                       children: [
                        Icon(Icons.group, color: Colors.blueAccent, size: 33),
                        Text(textAlign: TextAlign.center, "Pagos\nGrupales", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15))
                      ],
                    ),
                  ),
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(13))
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // centra verticalmente
                      crossAxisAlignment: CrossAxisAlignment.center, // centra horizontalmente
                       children: [
                        Icon(Icons.location_on, color: Colors.blueAccent, size: 33),
                        Text(textAlign: TextAlign.center, "Usuarios\nCercanos", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15))
                      ],
                    ),
                  ),
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(13))
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // centra verticalmente
                      crossAxisAlignment: CrossAxisAlignment.center, // centra horizontalmente
                       children: [
                        Icon(Icons.account_balance, color: Colors.blueAccent, size: 33),
                        Text(textAlign: TextAlign.center, "Cuentas\nCompartidas", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15))
                      ],
                    ),
                  )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 23, left: 33),
                    child: Align(alignment: Alignment.topLeft, child: Text("Ultimos Movimientos", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 23))),
                  ),
                  SizedBox(height: 23),
                  Container(
                    width: 333,
                    height: 263,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(10))
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 73,
                          width: 300,
                          color: Colors.white,
                          child: Column(
                            children: [
                              SizedBox(height: 13),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 13),
                                    child: Container(
                                      height: 43,
                                      width: 43,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.all(Radius.circular(10))
                                      ),
                                      child: Center(
                                        child: Icon(Icons.shopping_cart, color: Colors.blueAccent, size: 23),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 13),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Supermercado", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                                      Text("Hoy", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))
                                    ],
                                  ),
                                  SizedBox(width: 5),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text("-\$" + formatCurrencyMovimientos(5500, false), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                                        Text("05/09", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                              Divider(
                                color: Colors.grey, // color de la línea
                                thickness: 0.5,       // grosor de la línea
                                indent: 15,         // espacio desde la izquierda
                                endIndent: 15,      // espacio desde la derecha
                              ),
                          Container(
                          height: 73,
                          width: 300,
                          color: Colors.white,
                          child: Column(
                            children: [
                              SizedBox(height: 13),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 13),
                                    child: Container(
                                      height: 43,
                                      width: 43,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.all(Radius.circular(10))
                                      ),
                                      child: Center(
                                        child: Icon(Icons.arrow_upward_rounded, color: Colors.blueAccent, size: 23),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 13),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Recibido de Nahuel", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                                      Text("Ayer", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))
                                    ],
                                  ),
                                  SizedBox(width: 5),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        FittedBox(fit: BoxFit.scaleDown, child: Text("+\$" + formatCurrencyMovimientos(13050.50, true), style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1)),
                                        Text("04/09", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                         Divider(
                                color: Colors.grey, // color de la línea
                                thickness: 0.5,       // grosor de la línea
                                indent: 15,         // espacio desde la izquierda
                                endIndent: 15,      // espacio desde la derecha
                              ),
                          Container(
                          height: 73,
                          width: 300,
                          color: Colors.white,
                          child: Column(
                            children: [
                              SizedBox(height: 13),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 13),
                                    child: Container(
                                      height: 43,
                                      width: 43,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.all(Radius.circular(10))
                                      ),
                                      child: Center(
                                        child: Icon(Icons.arrow_upward_rounded, color: Colors.blueAccent, size: 23),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 13),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Pago en StockX", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                                      Text("Hace 5 Dias", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))
                                    ],
                                  ),
                                  SizedBox(width: 5),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text("-\$" + formatCurrencyMovimientos(138000, false), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                                        Text("01/09", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      )
    );
  }
}

class MoneyCounter extends StatelessWidget {
  final double amount;

  const MoneyCounter({super.key, required this.amount});

  Duration get duration {
    double seconds = 3 - (amount / 1000); // fórmula simple
    if (seconds < 1) seconds = 1;
    return Duration(seconds: seconds.toInt());
  }

  // Formatea el número como currency sin símbolo
  String formatCurrency(double value, bool showDecimals) {
    final formatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '',
      decimalDigits: showDecimals ? 2 : 0,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    // Determina si el saldo final tiene decimales
    final bool showDecimals = amount % 1 != 0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        // Durante la animación, mostramos decimales solo si hay centavos
        return Text(
          "\$" + formatCurrency(value, showDecimals),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 43,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}
*/

/*
import 'package:flutter/material.dart';

class MoneyScreen extends StatelessWidget {
  final List<String> users = [
    "https://i.pravatar.cc/150?img=1",
    "https://i.pravatar.cc/150?img=2",
    "https://i.pravatar.cc/150?img=3",
    "https://i.pravatar.cc/150?img=4",
    "https://i.pravatar.cc/150?img=5",
    "https://i.pravatar.cc/150?img=6",
  ];

  @override
  Widget build(BuildContext context) {
    int maxAvatars = 4;
    int displayCount = users.length > maxAvatars ? maxAvatars : users.length;
    int extraCount = users.length - maxAvatars;
    double overlap = 16;
    double avatarRadius = 16;
    double stackWidth = displayCount * overlap + avatarRadius * 2;

    return Row(
      children: [
        SizedBox(
          width: stackWidth,
      height: avatarRadius * 2,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(displayCount, (index) {
              return Positioned(
                left: index * overlap,
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: NetworkImage(users[index]),
                ),
              );
            })
              ..addAll(extraCount > 0
                  ? [
                      Positioned(
                        left: displayCount * overlap,
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.grey.shade400,
                          child: Text(
                            "+$extraCount",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ]
                  : []),
          ),
        ),
        const SizedBox(width: 8),
        Text("${users.length} people", style: TextStyle(fontSize: 14)),
      ],
    );
  }
}
*/

/*
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class MoneyScreen extends StatefulWidget {

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  bool inicioVis = true;

  bool grupos1Vis = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Stack(
        children: [
          inicio(context)
        ],
      ),
    );
  }

Widget inicio(BuildContext context) {

  double userMoney = 13500.88; // Cambiá el valor para probar con o sin decimales

  double screenWidth = MediaQuery.of(context).size.width;

    // Formatea los movimientos como currency 
  String formatCurrencyMovimientos(double value, bool showDecimals) {
    final formatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '',
      decimalDigits: showDecimals ? 2 : 0,
    );
    return formatter.format(value);
  }

  return Visibility(
    visible: inicioVis,
    child: Scaffold(
        body: Stack(
          children: [
            // Fondo sólido
            Container(
              width: screenWidth,
              height: 400,
              decoration: BoxDecoration(color: Colors.orange)),
    
            // Patrón SVG coloreable
            SvgPicture.asset(
              'assets/topography.svg',
              color: Colors.white.withOpacity(0.2), // color del patrón
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
    
            // Contenido encima
            Column(
              children: [
                Padding(
              padding: const EdgeInsets.only(top: 83),
              child: Center(
                child: Text("Saldo", style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Center(child: MoneyCounter(amount: userMoney)),
            ),
            SizedBox(height: 43),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Container(
                      height: 63,
                      width: 63,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100)
                      ),
                      child: Icon(Icons.add_rounded, color: Colors.orange, size: 33),
                    ),
                    SizedBox(height: 10),
                    Text("Ingresar", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                  ],
                ),
                Column(
                  children: [
                    Container(
                      height: 63,
                      width: 63,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100)
                      ),
                      child: Icon(Icons.arrow_forward, color: Colors.orange, size: 33),
                    ),
                    SizedBox(height: 10),
                    Text("Enviar", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                  ],
                ),
                Column(
                  children: [
                    Container(
                      height: 63,
                      width: 63,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100)
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.orange, size: 33),
                    ),
                    SizedBox(height: 10),
                    Text("Cobrar", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                  ],
                ),
              ]),
              SizedBox(height: 23),
              Expanded(
              child: Container(
                width: screenWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(50), topLeft: Radius.circular(50))
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 23, left: 33),
                      child: Align(alignment: Alignment.topLeft, child: Text("Mas formas de pagar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 23))),
                    ),
                    SizedBox(height: 23),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          child: Container(
                                                height: 100,
                                                width: 100,
                                                decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(13)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange, // sombra suave
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                                                ),
                                                child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, // centra verticalmente
                          crossAxisAlignment: CrossAxisAlignment.center, // centra horizontalmente
                           children: [
                            Icon(Icons.group, color: Colors.blueAccent, size: 33),
                            Text(textAlign: TextAlign.center, "Pagos\nGrupales", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15))
                          ],
                                                ),
                                              ),
                          onTap: () {
                            setState(() {
                              inicioVis = false;
                              grupos1Vis = true;
                            });
                          },
                        ),
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(13)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange, // sombra suave
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // centra verticalmente
                        crossAxisAlignment: CrossAxisAlignment.center, // centra horizontalmente
                         children: [
                          Icon(Icons.location_on, color: Colors.blueAccent, size: 33),
                          Text(textAlign: TextAlign.center, "Usuarios\nCercanos", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15))
                        ],
                      ),
                    ),
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(13)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange, // sombra suave
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // centra verticalmente
                        crossAxisAlignment: CrossAxisAlignment.center, // centra horizontalmente
                         children: [
                          Icon(Icons.account_balance, color: Colors.blueAccent, size: 33),
                          Text(textAlign: TextAlign.center, "Cuentas\nCompartidas", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15))
                        ],
                      ),
                    )
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 23, left: 33),
                      child: Align(alignment: Alignment.topLeft, child: Text("Ultimos Movimientos", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 23))),
                    ),
                    SizedBox(height: 23),
                    Container(
                      width: 333,
                      height: 263,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(10))
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 73,
                            width: 300,
                            color: Colors.white,
                            child: Column(
                              children: [
                                SizedBox(height: 13),
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 13),
                                      child: Container(
                                        height: 43,
                                        width: 43,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.all(Radius.circular(10))
                                        ),
                                        child: Center(
                                          child: Icon(Icons.shopping_cart, color: Colors.blueAccent, size: 23),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 13),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Supermercado", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                                        Text("Hoy", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))
                                      ],
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text("-\$" + formatCurrencyMovimientos(5500, false), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                                          Text("05/09", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                                Divider(
                                  color: Colors.grey, // color de la línea
                                  thickness: 0.5,       // grosor de la línea
                                  indent: 15,         // espacio desde la izquierda
                                  endIndent: 15,      // espacio desde la derecha
                                ),
                            Container(
                            height: 73,
                            width: 300,
                            color: Colors.white,
                            child: Column(
                              children: [
                                SizedBox(height: 13),
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 13),
                                      child: Container(
                                        height: 43,
                                        width: 43,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.all(Radius.circular(10))
                                        ),
                                        child: Center(
                                          child: Icon(Icons.arrow_upward_rounded, color: Colors.blueAccent, size: 23),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 13),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Recibido de Nahuel", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                                        Text("Ayer", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))
                                      ],
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          FittedBox(fit: BoxFit.scaleDown, child: Text("+\$" + formatCurrencyMovimientos(13050.50, true), style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1)),
                                          Text("04/09", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                           Divider(
                                  color: Colors.grey, // color de la línea
                                  thickness: 0.5,       // grosor de la línea
                                  indent: 15,         // espacio desde la izquierda
                                  endIndent: 15,      // espacio desde la derecha
                                ),
                            Container(
                            height: 73,
                            width: 300,
                            color: Colors.white,
                            child: Column(
                              children: [
                                SizedBox(height: 13),
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 13),
                                      child: Container(
                                        height: 43,
                                        width: 43,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.all(Radius.circular(10))
                                        ),
                                        child: Center(
                                          child: Icon(Icons.arrow_upward_rounded, color: Colors.blueAccent, size: 23),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 13),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Pago en StockX", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                                        Text("Hace 5 Dias", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))
                                      ],
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text("-\$" + formatCurrencyMovimientos(138000, false), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                                          Text("01/09", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
              ])
          ],
        ),
      ),
  );

}
}

class MoneyCounter extends StatelessWidget {
  final double amount;

  const MoneyCounter({super.key, required this.amount});

  Duration get duration {
    double seconds = 3 - (amount / 1000); // fórmula simple
    if (seconds < 1) seconds = 1;
    return Duration(seconds: seconds.toInt());
  }

  // Formatea el número como currency sin símbolo
  String formatCurrency(double value, bool showDecimals) {
    final formatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '',
      decimalDigits: showDecimals ? 2 : 0,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    // Determina si el saldo final tiene decimales
    final bool showDecimals = amount % 1 != 0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        // Durante la animación, mostramos decimales solo si hay centavos
        return Text(
          "\$" + formatCurrency(value, showDecimals),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 43,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }
}
*/

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MoneyScreen extends StatefulWidget {

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  List<String> userNames = [];

  Map<String, double> sliderValues = {}; // userId -> porcentaje
  Map<String, dynamic> usersData = {};   // userId -> {nombre, avatar}

  final TextEditingController _controller = TextEditingController();

  double valor = 0.0;
  double suma = 0.0;

    // Formatea el número como currency sin símbolo
  String formatCurrency(double value, bool showDecimals) {
    final formatter = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '',
      decimalDigits: showDecimals ? 2 : 0,
    );
    return formatter.format(value);
  }

  void _listenToUsers() {
    _db.child('grupos/12345/usuarios').onValue.listen((event) {
      final snapshotValue = event.snapshot.value;

      if (snapshotValue != null && snapshotValue is Map) {
        setState(() {
          usersData = snapshotValue.map((key, value) {
            return MapEntry(key.toString(), value);
          });

          // inicializar sliders si no tienen valor
          for (var entry in usersData.entries) {
            sliderValues.putIfAbsent(entry.key, () => 5);
          }
        });
      }
    });
  }

 bool verificarSuma() {
  double suma = 0.0;

  sliderValues.forEach((userId, porcentaje) {
    suma += valor * porcentaje / 100;
  });

  // Permitimos un pequeño margen de error por decimales
  return (suma - valor).abs() < 0.01;
}

double porcentajeRestante(String userId) {
  double sumaOtros = 0;
  sliderValues.forEach((id, value) {
    if (id != userId) {
      sumaOtros += value;
    }
  });
  return (100 - sumaOtros).clamp(0, 100); // nunca negativo ni mayor a 100
}

  @override
  void initState() {
    super.initState();
    _listenToUsers();
    _controller.addListener(() {
    setState(() {
      valor = double.tryParse(_controller.text) ?? 0.0;
    });
  });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Repartir gastos", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Container(
            width: 200,
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
              hintText: "Ingresar total",
              border: OutlineInputBorder(),
              ),
              style: const TextStyle(  // 👈 aquí cambias el color del texto
              color: Colors.white,
              fontSize: 16,
              )
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: usersData.entries.map((entry) {
                final userId = entry.key;
                final user = entry.value as Map;
                final nombre = user['nombre'] ?? 'Sin nombre';
                final avatar = user['avatar'] ??
                    "https://i.pravatar.cc/150?u=$userId"; // placeholder
            
                final value = sliderValues[userId] ?? 0.0;
            
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            backgroundImage: NetworkImage(avatar),
                            radius: 24,
                          ),
                          const SizedBox(width: 12),
                    
                          // Nombre + Slider
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Slider(
                                  value: value < 5 ? 5 : value,
                                  min: 5,
                                  max: porcentajeRestante(userId),
                                  divisions: 20, // pasos de 5 en 5
                                  activeColor: Colors.orange,
                                  inactiveColor: Colors.grey,
                                  label: "${value.toInt()}%",
                                  onChanged: (newValue) {
                                    setState(() {
                                      sliderValues[userId] = (newValue / 5).round() * 5; // siempre múltiplo de 5
                                    if (sliderValues[userId]! < 5) {
                                      sliderValues[userId] = 5; // nunca baja de 5
                                      _db.child('grupos/12345/usuarios/$nombre').update({
                                        "porcentaje": (newValue / 5).round() * 5,
                                        "pagar": double.parse((valor * sliderValues[userId]! / 100).toStringAsFixed(2))
                                      });
                                      }
                                      _db.child('grupos/12345/usuarios/$userId').update({
                                        "porcentaje": (newValue / 5).round() * 5,
                                        "pagar": double.parse((valor * sliderValues[userId]! / 100).toStringAsFixed(2))
                                      });
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                    
                          // Porcentaje a la derecha
                          Text(
                            "${value.toInt()}%",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text("Total a pagar: " + (valor * value / 100).toString(), style: TextStyle(color: Colors.white))
                  ],
                );
              }).toList(),
            ),
          ),
          GestureDetector(
            child: Container(
              height: 53,
              width: 300,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.all(Radius.circular(20))
              ),
              child: Center(
                child: Text((verificarSuma() ? "Pagar" : "Falta Dinero"), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
            ),
            onTap: () {
              print("AAA");
              //Obtener Datos
              final dbRef2 = FirebaseDatabase.instance.ref();

              dbRef2.child("grupos").child("12345").child("usuarios").onValue.listen((event) async{
      if (event.snapshot.exists){
        final data = event.snapshot.value as Map<dynamic, dynamic>;

          setState(() {
             
        double saldoPrueba = (data["usuario 1"]["pagar"]);

        print("Resultado: ${1000000.00 - saldoPrueba}");
          
          });
      }
    });
              //Fin Obtener Datos
            },
          ),
          SizedBox(height: 33)
        ],
      ),
    );
  }
}

