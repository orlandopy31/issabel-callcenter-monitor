-- Gestión de usuarios y permisos para Panel Issabel Call Center
-- Ejecutar con un usuario MySQL con privilegios CREATE/ALTER/INSERT.

CREATE DATABASE IF NOT EXISTS `callcenter_panel`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `callcenter_panel`;

CREATE TABLE IF NOT EXISTS `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(80) NOT NULL,
  `full_name` VARCHAR(160) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  `is_superadmin` TINYINT(1) NOT NULL DEFAULT 0,
  `must_change_password` TINYINT(1) NOT NULL DEFAULT 0,
  `last_login_at` DATETIME NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_username` (`username`),
  KEY `idx_users_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `permissions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(100) NOT NULL,
  `name` VARCHAR(160) NOT NULL,
  `category` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_permissions_code` (`code`),
  KEY `idx_permissions_category_sort` (`category`,`sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_permissions` (
  `user_id` INT UNSIGNED NOT NULL,
  `permission_id` INT UNSIGNED NOT NULL,
  `allowed` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`,`permission_id`),
  KEY `idx_user_permissions_permission` (`permission_id`),
  CONSTRAINT `fk_user_permissions_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_permissions_permission`
    FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `system_settings` (
  `setting_key` VARCHAR(100) NOT NULL,
  `setting_value` VARCHAR(255) NOT NULL,
  `label` VARCHAR(160) NOT NULL DEFAULT '',
  `description` VARCHAR(500) NULL,
  `updated_by` INT UNSIGNED NULL,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`setting_key`),
  KEY `idx_system_settings_updated_by` (`updated_by`),
  CONSTRAINT `fk_system_settings_updated_by`
    FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `audit_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NULL,
  `username` VARCHAR(80) NULL,
  `action` VARCHAR(100) NOT NULL,
  `detail` VARCHAR(500) NULL,
  `ip_address` VARCHAR(64) NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_audit_user_date` (`user_id`,`created_at`),
  KEY `idx_audit_action_date` (`action`,`created_at`),
  CONSTRAINT `fk_audit_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `permissions` (`code`,`name`,`category`,`description`,`sort_order`) VALUES
('dashboard.view','Ver Dashboard ejecutivo','Operación','Acceso al tablero ejecutivo principal.',10),
('live.view','Ver monitoreo en tiempo real','Operación','Visualiza el estado operativo y llamadas actuales de agentes.',20),
('supervision.view','Ver módulo de supervisión','Supervisión','Acceso a la pantalla de escucha, susurro y conferencia.',30),
('supervision.control','Ejecutar escucha/susurro/barge','Supervisión','Permite iniciar o cambiar sesiones ChanSpy mediante AMI.',40),
('productivity.view','Ver tablero de productividad','Operación','Acceso a indicadores y ranking de productividad.',50),
('agents.view','Ver actividad por agente','Operación','Acceso al detalle total y actividad de agentes.',60),
('outbound.view','Ver campañas salientes','Operación','Acceso a campañas salientes y sus métricas.',70),
('calls.view','Ver seguimiento de llamadas','Operación','Acceso al seguimiento unificado y trazabilidad de llamadas.',80),
('recordings.view','Escuchar/descargar grabaciones','Datos sensibles','Permite acceder a archivos de grabación de llamadas.',90),
('manual_calls.view','Ver llamadas manuales/directas','Operación','Acceso a llamadas manuales y directas por extensión.',100),
('pauses.view','Ver pausas','Control de gestión','Acceso a pausas y motivos por agente.',110),
('sessions.view','Ver sesiones','Control de gestión','Acceso a sesiones, login y logout de agentes.',120),
('abandoned.view','Ver abandonadas','Control de gestión','Acceso a llamadas abandonadas.',130),
('callbacks.view','Ver devoluciones','Control de gestión','Acceso a devoluciones y llamadas pendientes.',140),
('service_level.view','Ver nivel de servicio','Control de gestión','Acceso a SLA y llamadas no atendidas.',150),
('inbound_comparison.view','Ver comparativo entrantes','Control de gestión','Acceso al comparativo de llamadas entrantes.',160),
('after_hours.view','Ver fuera de horario','Control de gestión','Acceso a llamadas fuera del horario de atención.',170),
('forms.view','Ver formularios','Control de gestión','Acceso a formularios cargados por agentes.',180),
('reports.view','Ver centro de reportes','Reportería','Acceso al catálogo central de reportes.',190),
('reports.export','Exportar CSV/PDF','Reportería','Permite descargar reportes en CSV o PDF desde cualquier módulo.',200),
('users.manage','Administrar usuarios y permisos','Administración','Crear, editar, activar/desactivar usuarios y asignar permisos.',210),
('settings.sla.manage','Configurar política SLA','Administración','Modificar meta porcentual y tiempo máximo del SLA utilizado por los reportes.',220)
ON DUPLICATE KEY UPDATE
  `name`=VALUES(`name`),
  `category`=VALUES(`category`),
  `description`=VALUES(`description`),
  `sort_order`=VALUES(`sort_order`);

INSERT INTO `system_settings` (`setting_key`,`setting_value`,`label`,`description`) VALUES
('sla_seconds','20','Tiempo SLA (segundos)','Tiempo máximo de espera para considerar una llamada atendida dentro del SLA.'),
('sla_target_pct','80','Meta SLA (%)','Porcentaje objetivo de llamadas ofrecidas que deben ser atendidas dentro del tiempo SLA.')
ON DUPLICATE KEY UPDATE
  `label`=VALUES(`label`),
  `description`=VALUES(`description`);
