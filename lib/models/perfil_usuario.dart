enum PerfilUsuario {
  administrador,
  gestor,
  corretor,
  cliente;

  String get rotulo {
    switch (this) {
      case PerfilUsuario.administrador:
        return 'Administrador';
      case PerfilUsuario.gestor:
        return 'Gestor da Imobiliária';
      case PerfilUsuario.corretor:
        return 'Corretor';
      case PerfilUsuario.cliente:
        return 'Cliente';
    }
  }

  bool get eGestorOuAdmin =>
      this == PerfilUsuario.gestor || this == PerfilUsuario.administrador;

  static PerfilUsuario deString(String? valor, String? email) {
    if (valor != null && valor.isNotEmpty) {
      final v = valor.toUpperCase();
      if (v == 'GESTOR') return PerfilUsuario.gestor;
      if (v == 'ADMINISTRADOR' || v == 'ADMIN') return PerfilUsuario.administrador;
      if (v == 'CORRETOR') return PerfilUsuario.corretor;
      if (v == 'CLIENTE') return PerfilUsuario.cliente;
    }
    if (email != null && email.isNotEmpty) {
      final e = email.toLowerCase();
      if (e.contains('gestor')) return PerfilUsuario.gestor;
      if (e.contains('admin') || e.contains('adm')) return PerfilUsuario.administrador;
    }
    return PerfilUsuario.corretor;
  }
}
