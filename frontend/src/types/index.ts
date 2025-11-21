export const DegreeType = {
  ASSOCIATE: 0,
  BACHELOR: 1,
  MASTER: 2,
  DOCTORATE: 3,
  CERTIFICATE: 4,
  DIPLOMA: 5,
} as const;

export type DegreeType = typeof DegreeType[keyof typeof DegreeType];

export const Honors = {
  NONE: 0,
  CUM_LAUDE: 1,
  MAGNA_CUM_LAUDE: 2,
  SUMMA_CUM_LAUDE: 3,
  WITH_DISTINCTION: 4,
  WITH_HIGH_DISTINCTION: 5,
} as const;

export type Honors = typeof Honors[keyof typeof Honors];

export interface Credential {
  student: string;
  universityId: bigint;
  degreeType: DegreeType;
  major: string;
  gpa: number; // Scaled by 100
  honors: Honors;
  graduationDate: bigint;
  issuanceDate: bigint;
  metadataURI: string;
  isRevoked: boolean;
}

export interface University {
  admin: string;
  name: string;
  country: string;
  metadataURI: string;
  isActive: boolean;
  requiredSigners: bigint;
  registeredAt: bigint;
}

export interface VerificationResult {
  exists: boolean;
  isIssued: boolean;
  isRevoked: boolean;
  isValid: boolean;
  student: string;
  universityId: bigint;
  universityName: string;
  degreeType: DegreeType;
  major: string;
  gpa: number;
  honors: Honors;
  graduationDate: bigint;
}

export const DEGREE_TYPE_LABELS: Record<number, string> = {
  [DegreeType.ASSOCIATE]: "Associate",
  [DegreeType.BACHELOR]: "Bachelor",
  [DegreeType.MASTER]: "Master",
  [DegreeType.DOCTORATE]: "Doctorate",
  [DegreeType.CERTIFICATE]: "Certificate",
  [DegreeType.DIPLOMA]: "Diploma",
};

export const HONORS_LABELS: Record<number, string> = {
  [Honors.NONE]: "None",
  [Honors.CUM_LAUDE]: "Cum Laude",
  [Honors.MAGNA_CUM_LAUDE]: "Magna Cum Laude",
  [Honors.SUMMA_CUM_LAUDE]: "Summa Cum Laude",
  [Honors.WITH_DISTINCTION]: "With Distinction",
  [Honors.WITH_HIGH_DISTINCTION]: "With High Distinction",
};
