/********************************************************************************
*	�ļ�����:	condition.h														*
*	����ʱ�䣺	2014/06/24														*
*	��   �� :	xzben															*
*	�ļ�����:	ϵͳ��ʹ�õ��߳�ͬ����������										*
*********************************************************************************/

#ifndef __2014_10_12_CONDITION_H__
#define __2014_10_12_CONDITION_H__

#include <condition_variable>
#include <mutex>

/*
*
*/
class Condition
{
public:
	Condition();
	virtual ~Condition();

	void notify_one();
	void notify_all();

	void wait();
private:
	std::condition_variable  m_condition;
	std::mutex				 m_mutex;
	int						 m_NotifyCount;  //Ϊ�˷�ֹαװ�Ļ���
	int						 m_WaitCount;
};

#endif // !__2014_10_12_CONDITION_H__