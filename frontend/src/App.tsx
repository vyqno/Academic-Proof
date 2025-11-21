import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { WalletProvider } from './contexts/WalletContext';
import { Navbar } from './components/Navbar';
import { Home } from './pages/Home';
import { StudentDashboard } from './pages/StudentDashboard';
import { UniversityDashboard } from './pages/UniversityDashboard';
import { VerifierDashboard } from './pages/VerifierDashboard';

function App() {
  return (
    <WalletProvider>
      <Router>
        <div className="min-h-screen bg-gray-50">
          <Navbar />
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/student" element={<StudentDashboard />} />
            <Route path="/university" element={<UniversityDashboard />} />
            <Route path="/verifier" element={<VerifierDashboard />} />
          </Routes>
        </div>
      </Router>
    </WalletProvider>
  );
}

export default App;
