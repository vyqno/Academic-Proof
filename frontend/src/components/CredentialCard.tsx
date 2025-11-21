import type { Credential } from '../types';
import { formatGPA, formatDate, getDegreeLabel, getHonorsLabel } from '../utils/helpers';

interface CredentialCardProps {
  credential: Credential;
  credentialId: number;
  universityName?: string;
}

export const CredentialCard: React.FC<CredentialCardProps> = ({
  credential,
  credentialId,
  universityName
}) => {
  return (
    <div className="bg-white rounded-lg shadow-lg p-6 border-l-4 border-blue-600 hover:shadow-xl transition">
      <div className="flex justify-between items-start mb-4">
        <div>
          <h3 className="text-xl font-bold text-gray-800">
            {getDegreeLabel(credential.degreeType)} in {credential.major}
          </h3>
          <p className="text-gray-600">{universityName || `University #${credential.universityId}`}</p>
        </div>
        <span className="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm font-semibold">
          ID: {credentialId}
        </span>
      </div>

      <div className="grid grid-cols-2 gap-4 mb-4">
        <div>
          <p className="text-sm text-gray-500">GPA</p>
          <p className="text-lg font-semibold text-gray-800">{formatGPA(credential.gpa)}</p>
        </div>
        <div>
          <p className="text-sm text-gray-500">Honors</p>
          <p className="text-lg font-semibold text-gray-800">{getHonorsLabel(credential.honors)}</p>
        </div>
        <div>
          <p className="text-sm text-gray-500">Graduation Date</p>
          <p className="text-gray-800">{formatDate(credential.graduationDate)}</p>
        </div>
        <div>
          <p className="text-sm text-gray-500">Issued</p>
          <p className="text-gray-800">{formatDate(credential.issuanceDate)}</p>
        </div>
      </div>

      {credential.isRevoked && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-2 rounded">
          This credential has been revoked
        </div>
      )}
    </div>
  );
};
