import React, { useState, useEffect } from 'react'

const ClientList = () => {
  const [clients, setClients] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    const fetchClients = async () => {
      try {
        const response = await fetch("/clients.json")
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        const data = await response.json()
        setClients(data)
      } catch (err) {
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }

    fetchClients()
  }, [])

  if (loading) return <div>Loading clients...</div>
  if (error) return <div className="alert alert-danger">Error: {error}</div>

  return (
    <div>
      <h2 className="mb-4">Clients</h2>
      {clients.groups && clients.groups.map(group => (
        <div key={group.id} className="card mb-4">
          <div className="card-header">
            <h3 className="card-title">{group.title}</h3>
          </div>
          <div className="card-body">
            {clients.items_page && clients.items_page.items && 
             clients.items_page.items.filter(item => item.group.id === group.id).map(item => (
              <div key={item.id} className="mb-3">
                <h4>{item.name}</h4>
                <div className="row">
                  {item.column_values.map(column => (
                    <div key={column.id} className="col-md-4 mb-2">
                      <strong>{column.id}: </strong>
                      {column.text || 'N/A'}
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  )
}

export default ClientList 