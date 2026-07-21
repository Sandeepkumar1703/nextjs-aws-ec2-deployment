import React from 'react'

const Home: React.FC = () => {
  return (
    <main style={{fontFamily: 'Inter, system-ui, -apple-system'}}>
      <div style={{maxWidth: 960, margin: '0 auto', padding: '2rem'}}>
        <header style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
          <h1 style={{margin: 0}}>Next.js on EC2 (Free Tier)</h1>
        </header>

        <section style={{marginTop: '2rem'}}>
          <p>
            This is a minimal, responsive Next.js application intended to be deployed in a Docker
            container on an AWS EC2 instance. The infrastructure for this project is provisioned
            with Terraform and the CI/CD flow uses GitHub Actions to build and push images to
            Amazon ECR and update the EC2 instance.
          </p>

          <div style={{display: 'grid', gridTemplateColumns: '1fr', gap: '1rem', marginTop: '1.5rem'}}>
            <div style={{padding: '1rem', border: '1px solid #e5e7eb', borderRadius: 8}}>
              <h2 style={{marginTop: 0}}>Fast</h2>
              <p>Built with Next.js + TypeScript and containerized for production.</p>
            </div>
            <div style={{padding: '1rem', border: '1px solid #e5e7eb', borderRadius: 8}}>
              <h2 style={{marginTop: 0}}>Free Tier Friendly</h2>
              <p>Uses t2.micro EC2 and other Free Tier eligible resources where possible.</p>
            </div>
          </div>
        </section>

        <footer style={{marginTop: '3rem', color: '#6b7280'}}>
          <small>Follow README instructions to deploy this project.</small>
        </footer>
      </div>
    </main>
  )
}

export default Home
