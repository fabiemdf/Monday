import React from 'react'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import Header from './Header'
import ClientList from './ClientList'
import Home from './Home'

const App = () => {
  return (
    <Router>
      <div>
        <Header />
        <div className="container">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/clients" element={<ClientList />} />
            <Route path="/claims" element={<div>Claims Page (Coming Soon)</div>} />
            <Route path="/leads" element={<div>Leads Page (Coming Soon)</div>} />
          </Routes>
        </div>
      </div>
    </Router>
  )
}

export default App 