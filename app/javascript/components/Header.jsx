import React from 'react'
import { Link, useLocation } from 'react-router-dom'

const Header = () => {
  const location = useLocation()

  const isActive = (path) => {
    return location.pathname === path ? 'active' : ''
  }

  return (
    <nav className="navbar navbar-expand-lg navbar-light bg-light">
      <div className="container">
        <Link className="navbar-brand" to="/">
          Monday.com Integration
        </Link>
        
        <button 
          className="navbar-toggler" 
          type="button" 
          data-bs-toggle="collapse" 
          data-bs-target="#navbarNav"
        >
          <span className="navbar-toggler-icon"></span>
        </button>

        <div className="collapse navbar-collapse" id="navbarNav">
          <ul className="navbar-nav me-auto">
            <li className="nav-item">
              <Link 
                className={`nav-link ${isActive('/')}`} 
                to="/"
              >
                Home
              </Link>
            </li>
            
            <li className="nav-item dropdown">
              <a 
                className="nav-link dropdown-toggle" 
                href="#" 
                role="button" 
                data-bs-toggle="dropdown"
              >
                Clients
              </a>
              <ul className="dropdown-menu">
                <li>
                  <Link className="dropdown-item" to="/clients">
                    All Clients
                  </Link>
                </li>
                <li>
                  <Link className="dropdown-item" to="/clients/new">
                    New Client
                  </Link>
                </li>
                <li><hr className="dropdown-divider" /></li>
                <li>
                  <Link className="dropdown-item" to="/clients/import">
                    Import Clients
                  </Link>
                </li>
              </ul>
            </li>

            <li className="nav-item dropdown">
              <a 
                className="nav-link dropdown-toggle" 
                href="#" 
                role="button" 
                data-bs-toggle="dropdown"
              >
                Claims
              </a>
              <ul className="dropdown-menu">
                <li>
                  <Link className="dropdown-item" to="/claims">
                    All Claims
                  </Link>
                </li>
                <li>
                  <Link className="dropdown-item" to="/claims/new">
                    New Claim
                  </Link>
                </li>
                <li><hr className="dropdown-divider" /></li>
                <li>
                  <Link className="dropdown-item" to="/claims/reports">
                    Reports
                  </Link>
                </li>
              </ul>
            </li>

            <li className="nav-item dropdown">
              <a 
                className="nav-link dropdown-toggle" 
                href="#" 
                role="button" 
                data-bs-toggle="dropdown"
              >
                Leads
              </a>
              <ul className="dropdown-menu">
                <li>
                  <Link className="dropdown-item" to="/leads">
                    All Leads
                  </Link>
                </li>
                <li>
                  <Link className="dropdown-item" to="/leads/new">
                    New Lead
                  </Link>
                </li>
                <li><hr className="dropdown-divider" /></li>
                <li>
                  <Link className="dropdown-item" to="/leads/import">
                    Import Leads
                  </Link>
                </li>
              </ul>
            </li>
          </ul>

          <ul className="navbar-nav">
            <li className="nav-item dropdown">
              <a 
                className="nav-link dropdown-toggle" 
                href="#" 
                role="button" 
                data-bs-toggle="dropdown"
              >
                <i className="fas fa-user"></i> Account
              </a>
              <ul className="dropdown-menu dropdown-menu-end">
                <li>
                  <Link className="dropdown-item" to="/profile">
                    Profile
                  </Link>
                </li>
                <li>
                  <Link className="dropdown-item" to="/settings">
                    Settings
                  </Link>
                </li>
                <li><hr className="dropdown-divider" /></li>
                <li>
                  <a className="dropdown-item" href="/users/sign_out" data-turbo-method="delete">
                    Sign Out
                  </a>
                </li>
              </ul>
            </li>
          </ul>
        </div>
      </div>
    </nav>
  )
}

export default Header 