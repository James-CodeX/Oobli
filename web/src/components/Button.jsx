/** Chunky 3D button: pressing it pushes the face down onto its shadow. */
export function Button({ variant = 'primary', size, href, children, className = '', ...props }) {
  const cls = ['btn', `btn-${variant}`, size && `btn-${size}`, className].filter(Boolean).join(' ');
  return href ? (
    <a className={cls} href={href} {...props}>{children}</a>
  ) : (
    <button type="button" className={cls} {...props}>{children}</button>
  );
}
