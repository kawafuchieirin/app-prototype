import type { TodoStats } from '../types/todo'

interface StatsCardProps {
  stats: TodoStats
}

export function StatsCard({ stats }: StatsCardProps) {
  return (
    <div className="stats-card">
      <div className="stats-header">
        <h2>Progress Overview</h2>
        <span className="completion-rate">{stats.completion_rate}%</span>
      </div>

      <div className="progress-bar">
        <div
          className="progress-fill"
          style={{ width: `${stats.completion_rate}%` }}
        />
      </div>

      <div className="stats-grid">
        <div className="stat-item pending">
          <span className="stat-count">{stats.pending}</span>
          <span className="stat-label">Pending</span>
        </div>
        <div className="stat-item in-progress">
          <span className="stat-count">{stats.in_progress}</span>
          <span className="stat-label">In Progress</span>
        </div>
        <div className="stat-item completed">
          <span className="stat-count">{stats.completed}</span>
          <span className="stat-label">Completed</span>
        </div>
        <div className="stat-item total">
          <span className="stat-count">{stats.total}</span>
          <span className="stat-label">Total</span>
        </div>
      </div>
    </div>
  )
}
