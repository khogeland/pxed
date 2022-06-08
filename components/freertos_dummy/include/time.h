//TODO JUST PATCH NIM I GUESS
#if !defined(__clockid_t_defined) && !defined(_CLOCKID_T_DECLARED)
typedef	int	clockid_t;
#define	__clockid_t_defined
#define	_CLOCKID_T_DECLARED
#endif
#define CLOCKS_PER_SEC 1000
#define CLOCK_REALTIME 1
#define CLOCK_PROCESS_CPUTIME_ID 2
#define CLOCK_THREAD_CPUTIME_ID 3
#define TIMER_ABSTIME 4
#define CLOCK_MONOTONIC 4
