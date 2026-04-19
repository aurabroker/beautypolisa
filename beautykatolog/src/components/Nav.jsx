import { Link, useLocation } from 'react-router-dom'

export default function Nav() {
  const { pathname } = useLocation()

  return (
    <nav style={{
      background: '#fff', borderBottom: '1px solid #e2e8f0',
      position: 'sticky', top: 0, zIndex: 100,
      boxShadow: '0 1px 4px rgba(0,0,0,.06)'
    }}>
      <div className="container" style={{ padding: '.6rem 1.25rem', display: 'flex', alignItems: 'center', gap: '.75rem' }}>
        <Link to="/" style={{ fontFamily: 'Montserrat,sans-serif', fontWeight: 900, fontSize: '1.1rem', color: '#7c3aed', letterSpacing: '-.02em', flexShrink: 0 }}>
          Beauty<span style={{ color: '#e11d48' }}>Katalog</span>
        </Link>

        <div style={{ display: 'flex', gap: '.25rem', flex: 1, overflowX: 'auto' }}>
          {[
            { to: '/',       label: 'Katalog salonów' },
            { to: '/panel',  label: 'Mój salon' },
          ].map(({ to, label }) => (
            <Link key={to} to={to} style={{
              padding: '.3rem .75rem', borderRadius: '9999px', fontSize: '.8rem', fontWeight: 600,
              color: pathname === to ? '#7c3aed' : '#64748b',
              background: pathname === to ? '#ede9fe' : 'transparent',
              whiteSpace: 'nowrap',
            }}>
              {label}
            </Link>
          ))}
        </div>

        <Link to="/panel" className="btn btn-primary" style={{ padding: '.4rem 1rem', borderRadius: '9999px', fontSize: '.8rem', flexShrink: 0 }}>
          + Dodaj salon
        </Link>
      </div>
    </nav>
  )
}
