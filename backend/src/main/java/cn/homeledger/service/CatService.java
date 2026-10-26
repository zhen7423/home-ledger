package cn.homeledger.service;

import java.util.List;

import cn.homeledger.dto.CatCreateRequest;
import cn.homeledger.dto.CatUpdateRequest;
import cn.homeledger.vo.CatResponse;

/**
 * §4.3.1 猫咪档案。全家共享的一份清单，不是每个成员各记一份。
 * <p>
 * familyId 的取法与 {@link PaymentAccountService} 相同：cat 不在租户白名单内（§5.2），
 * 拦截器逐条 SQL 注入 family_id，服务层再显式带一次。
 */
public interface CatService {

	/** 列表。在册的在前，其后按建档先后。includeArchived=false 时归档的那些整行不出现。 */
	List<CatResponse> list(boolean includeArchived);

	/** 建档。在册的猫满 10 只即拒绝，归档的不占名额。 */
	CatResponse create(Long userId, CatCreateRequest request);

	/** 整份表单覆盖。不碰 enabled——归档是另一个动作，见 {@link #archive}。 */
	CatResponse update(Long userId, Long id, CatUpdateRequest request);

	/** 归档与恢复同一个开关。恢复时重数在册数，超上限一样被拒。 */
	CatResponse archive(Long userId, Long id);

	/** 软删除。名下有过任何驱虫记录（含已软删的）即拒绝，只能归档。 */
	void delete(Long userId, Long id);

	/**
	 * 上传并设置档案照片（§4.3.1 / A6）。校验在 {@code PhotoService}（体积、格式魔数），
	 * 新文件先落盘、再改列；旧照片由本方法清理，避免每次换图都往磁盘上留一份。
	 */
	CatResponse setPhoto(Long userId, Long id, byte[] data);

	/** 删除档案照片：清列 + 删文件。 */
	CatResponse clearPhoto(Long userId, Long id);

}
