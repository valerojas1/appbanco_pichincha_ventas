import 'package:flutter/material.dart';
import '../model/cliente_cartera_model.dart';

class CarteraViewModel extends ChangeNotifier {
  // Lista hardcodeada de 5 clientes — S9
  final List<ClienteCarteraModel> clientes = [
    ClienteCarteraModel(
      nombre: 'María Elena Torres',
      dni: '45678901',
      tipoGestion: 'renovacion',
      estado: 'pendiente',
      direccion: 'Jr. Huancayo 234, El Tambo',
    ),
    ClienteCarteraModel(
      nombre: 'Roberto Quispe Huamán',
      dni: '32145678',
      tipoGestion: 'nuevo',
      estado: 'pendiente',
      direccion: 'Av. Ferrocarril 890, Huancayo',
    ),
    ClienteCarteraModel(
      nombre: 'Carmen Rosa Sulca',
      dni: '56789012',
      tipoGestion: 'cobranza',
      estado: 'visitado',
      direccion: 'Ca. Real 456, Chilca',
    ),
    ClienteCarteraModel(
      nombre: 'Luis Alberto Poma',
      dni: '78901234',
      tipoGestion: 'renovacion',
      estado: 'visitado',
      direccion: 'Jr. Loreto 123, Huancayo',
    ),
    ClienteCarteraModel(
      nombre: 'Ana Sofía Mendoza',
      dni: '90123456',
      tipoGestion: 'nuevo',
      estado: 'pendiente',
      direccion: 'Av. Giráldez 567, Huancayo',
    ),
  ];

  // Contadores derivados
  int get totalVisitas => clientes.length;
  int get visitados => clientes.where((c) => c.estado == 'visitado').length;
  int get pendientes => clientes.where((c) => c.estado == 'pendiente').length;

  // Cambiar estado de un cliente
  void marcarVisitado(int index) {
    clientes[index] = ClienteCarteraModel(
      nombre: clientes[index].nombre,
      dni: clientes[index].dni,
      tipoGestion: clientes[index].tipoGestion,
      estado: 'visitado',
      direccion: clientes[index].direccion,
    );
    notifyListeners();
  }
}