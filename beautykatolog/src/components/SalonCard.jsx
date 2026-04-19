import { Link } from 'react-router-dom'

export default function SalonCard({ salon: s }) {
  const cover = s.salon_photos?.find(p => p.is_cover)?.url ?? s.salon_photos?.[0]?.url ?? ''
  const cnt   = s.salon_services?.length ?? 0

  return (
    <Link to={`/salon/${s.id}`} className="card" style={{
      display: 'block', overflow: 'hidden', color: 'inherit',
      transition: 'transform .2s, box-shadow .2s',
    }}
      onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-3px)'; e.currentTarget.style.boxShadow = '0 12px 32px rgba(124,58,237,.15)' }}
      onMouseLeave={e => { e.currentTarget.style.transform = ''; e.currentTarget.style.boxShadow = '' }}
    >
      <div style={{ height: 190, overflow: 'hidden', background: 'linear-gradient(135deg,#ede9fe,#ddd6fe)', position: 'relative' }}>
        {cover
          ? <img src={cover} alt={s.name} loading="lazy" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          : <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', fontSize: '3.5rem' }}>💅</div>
        }
      </div>

      <div style={{ padding: '1.1rem' }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: '.5rem', marginBottom: '.35rem' }}>
          <h2 style={{ fontSize: '.975rem' }}>{s.name}</h2>
          {cnt > 0 && <span className="badge" style={{ flexShrink: 0 }}>{cnt}&nbsp;zab.</span>}
        </div>
        <p style={{ fontSize: '.8rem', color: '#64748b', marginBottom: '.5rem' }}>
          📍 {s.city}{s.street ? `, ${s.street}` : ''}
        </p>
        {(s.tagline || s.description) && (
          <p style={{ fontSize: '.82rem', color: '#475569', overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', marginBottom: '.5rem' }}>
            {s.tagline || s.description}
          </p>
        )}
        <span style={{ fontSize: '.8rem', color: '#7c3aed', fontWeight: 700 }}>Zobacz profil →</span>
      </div>
    </Link>
  )
}
