export default function Modal({ onClose, children }) {
  return (
    <div className="modal-bg" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="modal">
        <button className="modal-x" onClick={onClose} aria-label="Zamknij">&times;</button>
        {children}
      </div>
    </div>
  )
}
