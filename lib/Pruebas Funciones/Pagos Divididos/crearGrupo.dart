// ignore_for_file: use_key_in_widget_constructors, camel_case_types, sized_box_for_whitespace, avoid_print, non_constant_identifier_names, prefer_interpolation_to_compose_strings, unused_import, await_only_futures, unused_local_variable, collection_methods_unrelated_type, prefer_adjacent_string_concatenation, body_might_complete_normally_nullable, use_build_context_synchronously

import 'dart:core';
import 'dart:math';

import 'package:bluetooth/UI/menuPrincipal.dart';
import 'package:bluetooth/Pruebas%20Funciones/Pagos%20Divididos/repartirGastos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class crearGrupoPage extends StatefulWidget {

  @override
  State<crearGrupoPage> createState() => _crearGrupoPageState();
}

Random random = Random();

class _crearGrupoPageState extends State<crearGrupoPage> {
  

final dbRef = FirebaseDatabase.instance.ref();
User? usuario = FirebaseAuth.instance.currentUser;

final TextEditingController _controllerNameGrupo = TextEditingController();
final TextEditingController _controllerValorGrupo = TextEditingController();

final TextEditingController _controllerInvitarUserGrupo = TextEditingController();

  
  int id_grupo = 10000 + random.nextInt(90000);

  int avatarRandom = random.nextInt(10);

  String nameUser = "";

  bool crearGrupoVis = true;
  bool invitarGrupoVis = false;

  //Invitaciones
  bool invitaciones = false;

  List<String> listaUsuarios = [];

  List<String?> listaAvatares = [];

  Map<String, dynamic> usuariosMap =  {};

  Map<String, String?> usuariosAvatares = {};

  String id_invitacionStr = "";
  String avatarUser = "";
  String nombre_invitacion = "";

  String fechaActual = "";
  String horaActual = "";

  int valor_invitacion = 0;
  int id_invitacion = 0;

    int maxAvatars = 4;
    double overlap = 16;
    double avatarRadius = 16;
    int displayCount = 0;
    int extraCount = 0;
    double stackWidth = 0.0;
  //Fin Invitaciones

  Future<void> guardarID(String ID) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idGrupo', ID);
  }

  Future<void> leerShared() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameUser = prefs.getString('nombreUser')!; // null si no existe
      print("NOMBRE SHARED: $nameUser");
    });
  }

  Future<void> obtenerDatos() async {
    leerShared();

    Future.delayed(Duration(seconds: 1), (){
      dbRef.child("Usuarios Grupos").child(nameUser).onValue.listen((event){
      if (event.snapshot.exists){
        final data = event.snapshot.value as Map<dynamic, dynamic>;

          setState(() {
            nameUser = (data["Nombre"]);
            avatarUser = (data["Avatar"]);
          });

          print("NOMBRE: $nameUser");
          print("AVATAR: $avatarUser");
      }
    });

    DateTime ahora = DateTime.now();

    setState(() {
    fechaActual = DateFormat('dd-MM-yyyy').format(ahora);
    horaActual = DateFormat('HH:mm').format(ahora); 
    }); 
    });
  }

  Future<void> verificarInvitaciones() async {
  Future.delayed(Duration(seconds: 1), (){
    dbRef.child("Usuarios Grupos").child(nameUser).child("invitaciones").onValue.listen((event) async {
    if (event.snapshot.exists) {
      print("Invitaciones Activas");

      // 🔹 Obtener primera key directamente del snapshot actual
      id_invitacionStr = event.snapshot.children.first.key!;
      print("El primer ID de invitación es:" + " " + id_invitacionStr);

      id_invitacion = int.parse(id_invitacionStr);

      listaAvatares = usuariosAvatares.values.toList();

      guardarID(id_invitacionStr);

      Future.delayed(Duration(seconds: 1), () {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          invitaciones = true;

          nombre_invitacion = data[id_invitacionStr]["Nombre Grupo"];
          valor_invitacion = data[id_invitacionStr]["Valor"];
        });

        obtenerUsuariosGrupoInvitado();
      });
    } else {
      print("Sin Invitaciones");
    }
  });
  });
}

  Future<void> crearGrupo() async {
await dbRef.child("grupos").child(id_grupo.toString()).set({
"nombre": _controllerNameGrupo.text,
"Valor": _controllerValorGrupo.text,
"usuarios": nameUser,
"configuracion": "proximamente"
});

await dbRef.child("Usuarios Grupos").child(nameUser).child("mis grupos").child(id_grupo.toString()).set({
 "Nombre Grupo": _controllerNameGrupo.text,
 "Valor del Grupo": _controllerValorGrupo.text,
 "Creado": fechaActual + " " + "a las" + " " + horaActual
});

guardarID(id_grupo.toString());
}

  Future<void> datosUsuariosGrupo() async {

await dbRef.child("grupos").child(id_grupo.toString()).child("usuarios").child(nameUser).set({
"pagar": 0,
"porcentaje": 0,
"estado": "pendiente",
"avatar": avatarUser,
"nombre": nameUser
});

await dbRef.child("Usuarios Grupos").child(nameUser).child("mis grupos").child(id_grupo.toString()).child("usuarios").child(nameUser).set({
"pagar": 0,
"porcentaje": 0,
"estado": "pendiente",
"avatar": avatarUser,
"nombre": nameUser
});
}

  Future<void> obtenerUsuariosGrupoAdmin() async {
  Future.delayed(Duration(seconds: 3), () async {
    dbRef.child("grupos").child(id_grupo.toString()).child("usuarios").once().then((event) {
  if (event.snapshot.exists) {
    print("Raw snapshot: ${event.snapshot.value}");

    listaUsuarios = event.snapshot.children.map((child) => child.key!).toList();
    print("listaUsuarios: $listaUsuarios");

    usuariosMap = {
      for (var usuario in listaUsuarios) usuario: true
    };

    // Obtener avatar de cada usuario
        for (var child in event.snapshot.children) {
          String usuarioId = child.key!;
          String? avatar = (child.value as Map?)?['avatar'] as String?;
          usuariosAvatares[usuarioId] = avatar;
        }

    // Convertir a lista para poder usar índices
      listaAvatares = usuariosAvatares.values.toList();

    print("usuariosAvatares: $usuariosAvatares");

    print("usuariosMap: $usuariosMap");
  } else {
    print("No existen usuarios en el grupo $id_grupo");
  }
});

  });
}

  Future<void> obtenerUsuariosGrupoInvitado() async {
  Future.delayed(Duration(seconds: 3), () async {
    dbRef.child("grupos").child(id_invitacionStr).child("usuarios").once().then((event) {
      if (event.snapshot.exists) {
        listaUsuarios = event.snapshot.children.map((child) => child.key!).toList();
        print("listaUsuarios: $listaUsuarios");

        usuariosMap = {
          for (var usuario in listaUsuarios) usuario: true
        };

        usuariosAvatares.clear();
        for (var child in event.snapshot.children) {
          String usuarioId = child.key!;
          String? avatar = (child.value as Map?)?['avatar'] as String?;
          usuariosAvatares[usuarioId] = avatar;
        }

        listaAvatares = usuariosAvatares.values.toList();

        // 👇 actualizar counts para que se pinte el Stack
        setState(() {
          displayCount = listaAvatares.length > maxAvatars ? maxAvatars : listaAvatares.length;
          extraCount = listaAvatares.length - displayCount;
          stackWidth = displayCount * overlap + avatarRadius * 2;
        });

        print("usuariosAvatares: $usuariosAvatares");
        print("usuariosMap: $usuariosMap");
      } else {
        print("No existen usuarios en el grupo $id_grupo");
      }
    });
  });
}

  Future<void> sincronizarMisGrupos() async {
  final uid = usuario!.uid;

  // 1️⃣ Obtener todos los grupos del usuario
  final misGruposSnapshot = await dbRef.child("Usuarios Grupos").child(nameUser).child("mis grupos").once();

  if (misGruposSnapshot.snapshot.exists) {
    final misGrupos = misGruposSnapshot.snapshot.value as Map<dynamic, dynamic>;

    for (var grupoId in misGrupos.keys) {

      // 2️⃣ Obtener datos actualizados del grupo desde "Grupos"
      final grupoSnapshot = await dbRef.child("grupos").child(grupoId.toString()).once();

      if (grupoSnapshot.snapshot.exists) {
        final grupoData = grupoSnapshot.snapshot.value as Map<dynamic, dynamic>;

        // 3️⃣ Actualizar "mis grupos" con los datos actuales
        await dbRef.child("Usuarios Grupos").child(nameUser).child("mis grupos").child(grupoId.toString()).update({
          "Nombre Grupo": grupoData["nombre"] ?? "",
          "Valor del Grupo": grupoData["Valor"] ?? 0,
          "usuarios": grupoData["usuarios"] ?? {},
          "configuracion": grupoData["configuracion"] ?? ""
        });
      }
    }
  }
}

  @override
void initState() {
  super.initState();
  obtenerDatos();
  verificarInvitaciones();
  obtenerUsuariosGrupoInvitado();
  sincronizarMisGrupos();
}

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Stack(
        children: [
          crearGrupoWidget(),
          invitarGrupoWidget(),
        ],
      ),
    );
  }

  Widget crearGrupoWidget() {
    return Visibility(
      visible: crearGrupoVis,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text("Crear Grupo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
        body: Column(
          children: [
            SizedBox(height: 33),
            Center(
              child: Text("Nombre Del Grupo", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            SizedBox(height: 33),
            Center(
              child: Container(
                width: 300,
                child: TextField(
                  controller: _controllerNameGrupo,
                  decoration: const InputDecoration(
                  hintText: "Ingresar Nombre Del Grupo",
                  border: OutlineInputBorder(),
                  ),
                  style: const TextStyle( 
                  color: Colors.white,
                  fontSize: 16,
                  )
                ),
              ),
            ),
            SizedBox(height: 33),
            Center(
              child: Text("Valor Total", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            SizedBox(height: 33),
            Center(
              child: Container(
                width: 300,
                child: TextField(
                  controller: _controllerValorGrupo,
                  decoration: const InputDecoration(
                  hintText: "Ingresar Valor a Pagar",
                  border: OutlineInputBorder(),
                  ),
                  style: const TextStyle( 
                  color: Colors.white,
                  fontSize: 16,
                  )
                ),
              ),
            ),
            SizedBox(height: 33),
            Center(
              child: GestureDetector(
                child: Container(
                  height: 53,
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.all(Radius.circular(20))
                  ),
                  child: Center(
                    child: Text("Crear Grupo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                ),
                onTap: () {
                  crearGrupo();

                  Future.delayed(Duration(seconds: 1), (){
                    datosUsuariosGrupo();
                  });

                  setState(() {
                    crearGrupoVis = false;
                    invitarGrupoVis = true;
                  });
                  //Navigator.push(context, MaterialPageRoute(builder: (context) => invitarPage()));
                },
              ),
            ),
            if (invitaciones == true) ...[
            SizedBox(height: 53),
            Center(
              child: GestureDetector(
                child: Container(
                  height: 200,
                  width: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      width: 0.5,
                      color: Colors.orange,
                    )
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 13),
                      Text("Invitacion a $nombre_invitacion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 5),
                      Text("\$${valor_invitacion.toString()}", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 23),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
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
      backgroundImage: NetworkImage(listaAvatares[index]!),
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
        //const SizedBox(width: 8),
        //Text("${listaUsuarios.length} people", style: TextStyle(fontSize: 14,color: Colors.white)),
      ],
    ),
                      SizedBox(height: 33),
                      Container(
                    height: 33,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.all(Radius.circular(20))
                    ),
                    child: Center(
                      child: Text("Unirse", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                  ),
                    ],
                  ),
                ),
                onTap: () {
                  dbRef.child("grupos").child(id_invitacionStr).child("usuarios").child(nameUser).set({
                    "pagar": 0,
                    "porcentaje": 0,
                    "estado": "pendiente",
                    "avatar": avatarUser,
                    "nombre": nameUser
                  });
      
                  dbRef.child("Usuarios Grupos").child(nameUser).child("invitaciones").child(id_invitacionStr).remove();
      
                  dbRef.child("Usuarios Grupos").child(nameUser).child("mis grupos").child(id_invitacionStr).set({
                    "Nombre Grupo": nombre_invitacion,
                    "Valor del Grupo": valor_invitacion,
                    "Agregado": fechaActual + " " + "a las" + " " + horaActual
                  });

                  dbRef.child("Usuarios Grupos").child(nameUser).child("mis grupos").child(id_invitacionStr).child("usuarios").set(usuariosMap);

                  Future.delayed(Duration(seconds: 1), () {
                    Navigator.push(
                  context,
                    MaterialPageRoute(
                      builder: (context) => dividirGastos()));

                  });
                },
              ),
            ) ]
          ],
        ),
      ),
    );
  }

  Widget invitarGrupoWidget() {
    return Visibility(
      visible: invitarGrupoVis,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text("Invitar Al Grupo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        body: Column(
          children: [
            SizedBox(height: 33),
            Center(
              child: Text("Ingresar Nombre Del Usuario", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            SizedBox(height: 33),
            Center(
              child: Container(
                width: 300,
                child: TextField(
                  controller: _controllerInvitarUserGrupo,
                  decoration: const InputDecoration(
                  hintText: "Ingresar Nombre Del Usuario",
                  border: OutlineInputBorder(),
                  ),
                  style: const TextStyle( 
                  color: Colors.white,
                  fontSize: 16,
                  )
                ),
              ),
            ),
            SizedBox(height: 33),
            Center(
              child: GestureDetector(
                child: Container(
                    height: 53,
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.all(Radius.circular(20))
                    ),
                    child: Center(
                      child: Text("Invitar Al Grupo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                  ),
                  onTap: () {
                    obtenerUsuariosGrupoAdmin();

                    Future.delayed(Duration(seconds: 5), (){
                      dbRef.child("Usuarios Grupos").child(_controllerInvitarUserGrupo.text).child("invitaciones").child(id_grupo.toString()).set({
                      "Grupo ID": id_grupo,
                      "Nombre Grupo": _controllerNameGrupo.text,
                      "Valor": 83000
                    });

                    dbRef.child("Usuarios Grupos").child(_controllerInvitarUserGrupo.text).child("invitaciones").child(id_grupo.toString()).child("usuarios").set(usuariosMap);

                  /*
                    dbRef.child("Usuarios Grupos").child(_controllerInvitarUserGrupo.text).onValue.listen((event){
                      if (event.snapshot.exists) {
                        final data = event.snapshot.value as Map<dynamic, dynamic>;
                        String nameUserExternal = data["Nombre"];
                        dbRef.child("grupos").child("56774").child("usuarios").child(nameUserExternal).set({
                          "estado": "pendiente",
                          "porcentaje": 0,
                          "pagar": 0
                        });
                      } else {
                        print("Usuario No Encontrado");
                      }
                    });
                    */
                    });
                  },
              ),
            )
          ],
        ),
      ),
    );
  }

}