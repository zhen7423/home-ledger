package cn.homeledger.service;

import java.util.List;

import cn.homeledger.dto.BabyCreateRequest;
import cn.homeledger.dto.BabyUpdateRequest;
import cn.homeledger.vo.BabyResponse;

/**
 * §4.4.1 宝宝档案。
 */
public interface BabyService {

	/** 在册的在前，其后按建档先后。includeArchived=false 时归档的那些整行不出现（§8）。 */
	List<BabyResponse> list(boolean includeArchived);

	/** 建档。同一事务内生成该宝宝的应种清单（§8）。 */
	BabyResponse create(Long userId, BabyCreateRequest request);

	/** 整份表单覆盖。改了 birth_date 就在同一事务内整份重算清单（§8、§4.4.4）。 */
	BabyResponse update(Long userId, Long id, BabyUpdateRequest request);

	/** 归档与恢复同一个开关，服务端按当前状态判方向（同 CatService.archive）。 */
	BabyResponse archive(Long userId, Long id);

	/** 软删除。名下四张录入表里有过任何记录（含已软删的）即拒绝，只能归档。 */
	void delete(Long userId, Long id);

	/**
	 * 上传并设置档案照片（§4.4.1 / A6）。校验在 {@code PhotoService}，旧照片由本方法清理。
	 */
	BabyResponse setPhoto(Long userId, Long id, byte[] data);

	/** 删除档案照片：清列 + 删文件。 */
	BabyResponse clearPhoto(Long userId, Long id);

}
