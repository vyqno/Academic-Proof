import { Link } from 'react-router-dom';
import { useWallet } from '../contexts/WalletContext';
import { formatAddress } from '../utils/helpers';

export const Navbar = () => {
  const { account, connectWallet, disconnectWallet, isConnecting } = useWallet();

  return (
    <nav className="bg-gradient-to-r from-blue-600 to-blue-800 text-white shadow-lg">
      <div className="container mx-auto px-4 py-4">
        <div className="flex justify-between items-center">
          <div className="flex items-center space-x-8">
            <Link to="/" className="text-2xl font-bold hover:text-blue-200 transition">
              Academic Proof
            </Link>
            <div className="hidden md:flex space-x-4">
              <Link to="/student" className="hover:text-blue-200 transition px-3 py-2 rounded">
                Student
              </Link>
              <Link to="/university" className="hover:text-blue-200 transition px-3 py-2 rounded">
                University
              </Link>
              <Link to="/verifier" className="hover:text-blue-200 transition px-3 py-2 rounded">
                Verifier
              </Link>
            </div>
          </div>

          <div>
            {!account ? (
              <button
                onClick={connectWallet}
                disabled={isConnecting}
                className="bg-white text-blue-600 px-6 py-2 rounded-lg font-semibold hover:bg-blue-50 transition disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isConnecting ? 'Connecting...' : 'Connect Wallet'}
              </button>
            ) : (
              <div className="flex items-center space-x-4">
                <span className="bg-blue-700 px-4 py-2 rounded-lg font-mono">
                  {formatAddress(account)}
                </span>
                <button
                  onClick={disconnectWallet}
                  className="bg-red-500 text-white px-4 py-2 rounded-lg hover:bg-red-600 transition"
                >
                  Disconnect
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
};
