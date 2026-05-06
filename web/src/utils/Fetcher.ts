import axios from 'axios'
import { RETRY_COUNT } from './Constant'
export const apiUrl = `${localStorage.getItem('API_URL') || process.env.REACT_APP_API_URL || ''}/api/v1`
export const req = axios.create({
  baseURL: apiUrl,
  withCredentials: true
})
req.interceptors.request.use(
  config => {
    const accessToken = localStorage.getItem('accessToken')
    if (accessToken) {
      config.headers['Authorization'] = accessToken.startsWith('Bearer ') ? accessToken : `Bearer ${accessToken}`
    }
    return config
  },
  error => Promise.reject(error)
)

req.interceptors.response.use(
  response => {
    // Store tokens if present in response
    if (response.data?.accessToken) {
      localStorage.setItem('accessToken', response.data.accessToken)
    }
    if (response.data?.refreshToken) {
      localStorage.setItem('refreshToken', response.data.refreshToken)
    }

    try {
      const requests = [
        ...JSON.parse(sessionStorage.getItem('requests') || '[]'),
        {
          date: new Date().toISOString(),
          ref: location.href,
          ...response
        }
      ]
      sessionStorage.setItem('requests', JSON.stringify(requests.slice(-200)))
    } catch (error) {
      // ignore
    }
    return response
  },
  async error => {
    try {
      const requests = [
        ...JSON.parse(sessionStorage.getItem('requests') || '[]'),
        {
          date: new Date().toISOString(),
          ref: location.href,
          ...error
        }
      ]
      sessionStorage.setItem('requests', JSON.stringify(requests.slice(-200)))
    } catch (error) {
      // ignore
    }
    if (!error.response) return Promise.reject(error)
    const { config, response: { status, data } } = error
    if (status === 401 && data?.details?.errorMessage !== 'SESSION_PASSWORD_NEEDED') {
      try {
        const refreshToken = localStorage.getItem('refreshToken')
        const { data: refreshData } = await axios.post(`${apiUrl}/auth/refreshToken`, { refreshToken }, { withCredentials: true })
        if (refreshData?.accessToken) {
          localStorage.setItem('accessToken', refreshData.accessToken)
          localStorage.setItem('refreshToken', refreshData.refreshToken)
          config.headers['Authorization'] = `Bearer ${refreshData.accessToken}`
        }
      } catch (error) {
        localStorage.removeItem('accessToken')
        localStorage.removeItem('refreshToken')
        return Promise.reject(error)
      }
      return axios(config)
    } else if (status === 429) {
      await new Promise(resolve => setTimeout(resolve, data.retryAfter || 1000))
      return req(config)
    } else if (status > 500) {
      config.headers = {
        ...config?.headers || {},
        'x-retry-count': config.headers['x-retry-count'] || 0
      }
      if (config.headers['x-retry-count'] < RETRY_COUNT) {
        await new Promise(resolve => setTimeout(resolve, ++config.headers['x-retry-count'] * 3000))
        return req(config)
      }
    }
    return Promise.reject(error)
  }
)
export const fetcher = async (url: string, authorization?: string): Promise<any> => {
  const fetch = async () => {
    const { data } = await req.get(url, {
      ...authorization ? { headers: { authorization: `Bearer ${authorization}` } } : {},
      withCredentials: true
    })
    return data
  }
  try {
    return await fetch()
  } catch ({ response }) {
    throw response
  }
}