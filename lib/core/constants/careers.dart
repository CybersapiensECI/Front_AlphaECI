/// Carreras — espejo exacto de `CareerEnum` de profile-service
/// (`profile-service/src/profile/domain/model/enum/career.enum.ts`).
/// El backend no valida un formato libre: hay que mandar uno de estos
/// valores tal cual.
const List<String> careers = [
  'SYSTEMS_ENGINEERING',
  'CIVIL_ENGINEERING',
  'INDUSTRIAL_ENGINEERING',
  'ELECTRONIC_ENGINEERING',
  'ELECTRICAL_ENGINEERING',
  'MECHANICAL_ENGINEERING',
  'BIOMEDICAL_ENGINEERING',
  'ENVIRONMENTAL_ENGINEERING',
  'STATISTICAL_ENGINEERING',
  'BIOTECHNOLOGY_ENGINEERING',
  'ARTIFICIAL_INTELLIGENCE_ENGINEERING',
  'CYBERSECURITY_ENGINEERING',
  'COMPUTER_SCIENCE',
  'MATHEMATICS',
  'DATA_SCIENCE',
  'BUSINESS_ADMINISTRATION',
  'ECONOMICS',
  'INFORMATION_TECHNOLOGY',
];

const Map<String, String> careerLabels = {
  'SYSTEMS_ENGINEERING': 'Ingeniería de Sistemas',
  'CIVIL_ENGINEERING': 'Ingeniería Civil',
  'INDUSTRIAL_ENGINEERING': 'Ingeniería Industrial',
  'ELECTRONIC_ENGINEERING': 'Ingeniería Electrónica',
  'ELECTRICAL_ENGINEERING': 'Ingeniería Eléctrica',
  'MECHANICAL_ENGINEERING': 'Ingeniería Mecánica',
  'BIOMEDICAL_ENGINEERING': 'Ingeniería Biomédica',
  'ENVIRONMENTAL_ENGINEERING': 'Ingeniería Ambiental',
  'STATISTICAL_ENGINEERING': 'Ingeniería Estadística',
  'BIOTECHNOLOGY_ENGINEERING': 'Ingeniería en Biotecnología',
  'ARTIFICIAL_INTELLIGENCE_ENGINEERING': 'Ingeniería en Inteligencia Artificial',
  'CYBERSECURITY_ENGINEERING': 'Ingeniería en Ciberseguridad',
  'COMPUTER_SCIENCE': 'Ciencias de la Computación',
  'MATHEMATICS': 'Matemáticas',
  'DATA_SCIENCE': 'Ciencia de Datos',
  'BUSINESS_ADMINISTRATION': 'Administración de Empresas',
  'ECONOMICS': 'Economía',
  'INFORMATION_TECHNOLOGY': 'Tecnología de la Información',
};

String careerLabel(String code) => careerLabels[code] ?? code;
