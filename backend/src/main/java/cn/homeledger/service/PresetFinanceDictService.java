package cn.homeledger.service;

/**
 * 预置收支字典的装配（§4.2.2、§4.2.1）。
 */
public interface PresetFinanceDictService {

	/**
	 * 给一个刚创建的家庭装入预置类别与支付方式：17 个大类、78 个小类、8 个支付方式。
	 * <p>
	 * operatorUserId 会写进每一行的 created_by。调用方此时还没有该家庭的登录态（创建家庭这个请求的
	 * JWT 里 familyId 是空的），所以本方法内部会临时把租户上下文切到目标家庭。
	 */
	void install(Long familyId, Long operatorUserId);

}
